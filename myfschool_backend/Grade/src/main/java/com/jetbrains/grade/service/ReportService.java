package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.AdminDashboardDTO;
import com.jetbrains.grade.dto.TeacherHomeroomDashboardDTO;
import com.jetbrains.grade.dto.TeacherSubjectStatsDTO;
import com.jetbrains.grade.model.Attendance;
import com.jetbrains.grade.model.Grade;
import com.jetbrains.grade.model.LeaveRequest;
import com.jetbrains.grade.model.SchoolClass;
import com.jetbrains.grade.model.Subject;
import com.jetbrains.grade.repository.*;
import com.jetbrains.grade.security.SecurityUtils;
import com.jetbrains.grade.security.TeacherAssignmentEnforcer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;

import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReportService {

    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final SchoolClassRepository schoolClassRepository;
    private final GradeRepository gradeRepository;
    private final AttendanceRepository attendanceRepository;
    private final LeaveRequestRepository leaveRequestRepository;
    private final SubjectRepository subjectRepository;
    private final TeacherAssignmentEnforcer teacherAssignmentEnforcer;

    public AdminDashboardDTO getAdminDashboard() {
        return getAdminDashboard("2025-2026", 1);
    }

    public AdminDashboardDTO getAdminDashboard(String academicYear, Integer semester) {
        if (!SecurityUtils.isAdmin()) {
            throw new AccessDeniedException("Chỉ quản trị viên mới có quyền xem báo cáo toàn trường");
        }

        String targetYear = (academicYear != null && !academicYear.isBlank()) ? academicYear : "2025-2026";
        int targetSemester = (semester != null && semester > 0) ? semester : 1;

        long totalStudents = studentRepository.count();
        long totalTeachers = teacherRepository.count();
        long totalClasses = studentRepository.findAll().stream()
                .map(s -> s.getSchoolClass() != null ? s.getSchoolClass().getId() : null)
                .filter(Objects::nonNull)
                .distinct()
                .count();

        List<Grade> allGrades = gradeRepository.findAll();
        List<Grade> filteredGrades = allGrades.stream()
                .filter(g -> g.getSchoolYear() == null || g.getSchoolYear().getName() == null || targetYear.equalsIgnoreCase(g.getSchoolYear().getName()))
                .filter(g -> g.getSemester() == null || targetSemester == g.getSemester())
                .collect(Collectors.toList());

        long totalGrades = filteredGrades.size();

        // Calculate student-level GPA and distribution across the 50 students
        Map<Integer, List<Grade>> gradesByStudent = filteredGrades.stream()
                .filter(g -> g.getStudent() != null && g.getStudent().getId() != null)
                .collect(Collectors.groupingBy(g -> g.getStudent().getId()));

        Map<String, Long> gradeDist = new LinkedHashMap<>();
        gradeDist.put("Xuất sắc", 0L);
        gradeDist.put("Giỏi", 0L);
        gradeDist.put("Khá", 0L);
        gradeDist.put("Trung bình", 0L);
        gradeDist.put("Yếu", 0L);

        List<Double> studentGpas = new ArrayList<>();
        for (Map.Entry<Integer, List<Grade>> entry : gradesByStudent.entrySet()) {
            double studentAvg = entry.getValue().stream()
                    .filter(g -> g.getAverageScore() != null)
                    .mapToDouble(Grade::getAverageScore)
                    .average()
                    .orElse(0.0);
            studentGpas.add(studentAvg);

            if (studentAvg >= 9.0) {
                gradeDist.put("Xuất sắc", gradeDist.get("Xuất sắc") + 1);
            } else if (studentAvg >= 8.0) {
                gradeDist.put("Giỏi", gradeDist.get("Giỏi") + 1);
            } else if (studentAvg >= 6.5) {
                gradeDist.put("Khá", gradeDist.get("Khá") + 1);
            } else if (studentAvg >= 5.0) {
                gradeDist.put("Trung bình", gradeDist.get("Trung bình") + 1);
            } else {
                gradeDist.put("Yếu", gradeDist.get("Yếu") + 1);
            }
        }

        double avgGpa = studentGpas.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
        avgGpa = round(avgGpa, 2);

        // Attendance stats for TODAY (prevent divide by zero if attendance not taken yet)
        LocalDate today = LocalDate.now();
        List<Attendance> allAttendances = attendanceRepository.findAll();
        List<Attendance> todayAttendances = allAttendances.stream()
                .filter(a -> a.getAttendanceDate() != null && today.equals(a.getAttendanceDate()))
                .collect(Collectors.toList());

        long totalAttendance = todayAttendances.size();
        long presentCount = todayAttendances.stream().filter(a -> "PRESENT".equalsIgnoreCase(a.getStatus())).count();
        long excusedCount = todayAttendances.stream().filter(a -> "EXCUSED_ABSENCE".equalsIgnoreCase(a.getStatus())).count();
        long unexcusedCount = todayAttendances.stream().filter(a -> "UNEXCUSED_ABSENCE".equalsIgnoreCase(a.getStatus())).count();
        long lateCount = todayAttendances.stream().filter(a -> "LATE".equalsIgnoreCase(a.getStatus())).count();

        double attendanceRate = totalAttendance > 0
                ? round((presentCount * 100.0) / totalAttendance, 2)
                : 0.0;

        List<LeaveRequest> leaveRequests = leaveRequestRepository.findAll();
        long totalLeaves = leaveRequests.size();
        long pendingLeaves = leaveRequests.stream().filter(l -> "Chờ duyệt".equalsIgnoreCase(l.getStatus()) || "PENDING".equalsIgnoreCase(l.getStatus())).count();
        long approvedLeaves = leaveRequests.stream().filter(l -> "APPROVED".equalsIgnoreCase(l.getStatus()) || "Đã duyệt".equalsIgnoreCase(l.getStatus())).count();
        long rejectedLeaves = leaveRequests.stream().filter(l -> "REJECTED".equalsIgnoreCase(l.getStatus()) || "Từ chối".equalsIgnoreCase(l.getStatus())).count();

        return AdminDashboardDTO.builder()
                .academicYear(targetYear)
                .semester(targetSemester)
                .totalStudents(totalStudents)
                .totalTeachers(totalTeachers)
                .totalClasses(totalClasses)
                .totalGrades(totalGrades)
                .averageSchoolGpa(avgGpa)
                .gradeDistribution(gradeDist)
                .totalAttendanceRecords(totalAttendance)
                .presentCount(presentCount)
                .excusedAbsenceCount(excusedCount)
                .unexcusedAbsenceCount(unexcusedCount)
                .lateCount(lateCount)
                .attendanceRate(attendanceRate)
                .totalLeaveRequests(totalLeaves)
                .pendingLeaveRequests(pendingLeaves)
                .approvedLeaveRequests(approvedLeaves)
                .rejectedLeaveRequests(rejectedLeaves)
                .build();
    }

    public TeacherHomeroomDashboardDTO getTeacherHomeroomDashboard() {
        return getTeacherHomeroomDashboard("2025-2026", 1);
    }

    public TeacherHomeroomDashboardDTO getTeacherHomeroomDashboard(String academicYear, Integer semester) {
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Học sinh không có quyền truy cập báo cáo giáo viên");
        }

        Integer teacherId = SecurityUtils.getCurrentTeacherId();
        if (teacherId == null) {
            throw new AccessDeniedException("Không tìm thấy thông tin giáo viên hợp lệ");
        }

        List<SchoolClass> homeroomClasses = schoolClassRepository.findByHomeroomTeacherId(teacherId);
        if (homeroomClasses.isEmpty()) {
            throw new AccessDeniedException("Giáo viên hiện tại không phải giáo viên chủ nhiệm của lớp học nào");
        }

        String targetYear = (academicYear != null && !academicYear.isBlank()) ? academicYear : "2025-2026";
        int targetSemester = (semester != null && semester > 0) ? semester : 1;

        SchoolClass homeroomClass = homeroomClasses.get(0);
        Integer classId = homeroomClass.getId();

        long totalStudents = studentRepository.countBySchoolClassId(classId);

        List<LeaveRequest> classLeaves = leaveRequestRepository.findByClassIdsOrderByCreatedAtDesc(List.of(classId));
        long totalLeaves = classLeaves.size();
        long pendingLeaves = classLeaves.stream().filter(l -> "Chờ duyệt".equalsIgnoreCase(l.getStatus()) || "PENDING".equalsIgnoreCase(l.getStatus())).count();

        LocalDate today = LocalDate.now();
        List<Attendance> classAttendances = attendanceRepository.findBySchoolClassId(classId).stream()
                .filter(a -> a.getAttendanceDate() != null && today.equals(a.getAttendanceDate()))
                .collect(Collectors.toList());

        long totalAttendance = classAttendances.size();
        long presentCount = classAttendances.stream().filter(a -> "PRESENT".equalsIgnoreCase(a.getStatus())).count();
        long excusedCount = classAttendances.stream().filter(a -> "EXCUSED_ABSENCE".equalsIgnoreCase(a.getStatus())).count();
        long unexcusedCount = classAttendances.stream().filter(a -> "UNEXCUSED_ABSENCE".equalsIgnoreCase(a.getStatus())).count();
        long lateCount = classAttendances.stream().filter(a -> "LATE".equalsIgnoreCase(a.getStatus())).count();

        double attendanceRate = totalAttendance > 0
                ? round((presentCount * 100.0) / totalAttendance, 2)
                : 0.0;

        List<Grade> classGrades = gradeRepository.findByStudentSchoolClassId(classId).stream()
                .filter(g -> g.getSchoolYear() == null || g.getSchoolYear().getName() == null || targetYear.equalsIgnoreCase(g.getSchoolYear().getName()))
                .filter(g -> g.getSemester() == null || targetSemester == g.getSemester())
                .collect(Collectors.toList());

        Map<Integer, List<Grade>> gradesByStudent = classGrades.stream()
                .filter(g -> g.getStudent() != null && g.getStudent().getId() != null)
                .collect(Collectors.groupingBy(g -> g.getStudent().getId()));

        Map<String, Long> gradeDist = new LinkedHashMap<>();
        gradeDist.put("Xuất sắc", 0L);
        gradeDist.put("Giỏi", 0L);
        gradeDist.put("Khá", 0L);
        gradeDist.put("Trung bình", 0L);
        gradeDist.put("Yếu", 0L);

        List<Double> studentGpas = new ArrayList<>();
        for (Map.Entry<Integer, List<Grade>> entry : gradesByStudent.entrySet()) {
            double studentAvg = entry.getValue().stream()
                    .filter(g -> g.getAverageScore() != null)
                    .mapToDouble(Grade::getAverageScore)
                    .average()
                    .orElse(0.0);
            studentGpas.add(studentAvg);

            if (studentAvg >= 9.0) {
                gradeDist.put("Xuất sắc", gradeDist.get("Xuất sắc") + 1);
            } else if (studentAvg >= 8.0) {
                gradeDist.put("Giỏi", gradeDist.get("Giỏi") + 1);
            } else if (studentAvg >= 6.5) {
                gradeDist.put("Khá", gradeDist.get("Khá") + 1);
            } else if (studentAvg >= 5.0) {
                gradeDist.put("Trung bình", gradeDist.get("Trung bình") + 1);
            } else {
                gradeDist.put("Yếu", gradeDist.get("Yếu") + 1);
            }
        }

        double avgGpa = studentGpas.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
        avgGpa = round(avgGpa, 2);

        return TeacherHomeroomDashboardDTO.builder()
                .academicYear(targetYear)
                .semester(targetSemester)
                .classId(classId)
                .className(homeroomClass.getClassName())
                .homeroomTeacherName(homeroomClass.getHomeroomTeacher() != null ? homeroomClass.getHomeroomTeacher().getFullName() : "")
                .totalStudents(totalStudents)
                .pendingLeaveRequests(pendingLeaves)
                .totalLeaveRequests(totalLeaves)
                .attendanceRate(attendanceRate)
                .totalAttendanceRecords(totalAttendance)
                .presentCount(presentCount)
                .excusedAbsenceCount(excusedCount)
                .unexcusedAbsenceCount(unexcusedCount)
                .lateCount(lateCount)
                .averageClassGpa(avgGpa)
                .gradeDistribution(gradeDist)
                .build();
    }

    public TeacherSubjectStatsDTO getTeacherSubjectStats(Integer classId, Integer subjectId) {
        if (classId == null || subjectId == null) {
            throw new IllegalArgumentException("Vui lòng cung cấp đầy đủ classId và subjectId");
        }

        SchoolClass sc = schoolClassRepository.findById(classId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lớp học với ID: " + classId));
        Subject sub = subjectRepository.findById(subjectId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy môn học với ID: " + subjectId));

        if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            if (currentTeacherId == null) {
                throw new AccessDeniedException("Không tìm thấy thông tin giáo viên hợp lệ");
            }
            if (!teacherAssignmentEnforcer.isSubjectTeacher(currentTeacherId, classId, subjectId)
                    && !teacherAssignmentEnforcer.isHomeroomTeacher(currentTeacherId, classId)) {
                throw new AccessDeniedException("Giáo viên không phụ trách môn học này tại lớp chỉ định");
            }
        }

        long totalStudents = studentRepository.countBySchoolClassId(classId);
        List<Grade> grades = gradeRepository.findByStudentSchoolClassIdAndSubjectId(classId, subjectId);
        long gradedCount = grades.size();

        double highest = grades.stream()
                .filter(g -> g.getAverageScore() != null)
                .mapToDouble(Grade::getAverageScore)
                .max()
                .orElse(0.0);

        double lowest = grades.stream()
                .filter(g -> g.getAverageScore() != null)
                .mapToDouble(Grade::getAverageScore)
                .min()
                .orElse(0.0);

        double average = grades.stream()
                .filter(g -> g.getAverageScore() != null)
                .mapToDouble(Grade::getAverageScore)
                .average()
                .orElse(0.0);

        long passCount = grades.stream()
                .filter(g -> g.getAverageScore() != null && g.getAverageScore() >= 5.0)
                .count();

        long failCount = grades.stream()
                .filter(g -> g.getAverageScore() != null && g.getAverageScore() < 5.0)
                .count();

        double passRate = gradedCount > 0 ? round((passCount * 100.0) / gradedCount, 2) : 0.0;

        return TeacherSubjectStatsDTO.builder()
                .classId(classId)
                .className(sc.getClassName())
                .subjectId(subjectId)
                .subjectName(sub.getSubjectName())
                .totalStudents(totalStudents)
                .gradedCount(gradedCount)
                .highestScore(round(highest, 2))
                .lowestScore(round(lowest, 2))
                .averageScore(round(average, 2))
                .passCount(passCount)
                .failCount(failCount)
                .passRate(passRate)
                .build();
    }

    private double round(double value, int places) {
        if (places < 0) throw new IllegalArgumentException();
        BigDecimal bd = BigDecimal.valueOf(value);
        bd = bd.setScale(places, RoundingMode.HALF_UP);
        return bd.doubleValue();
    }
}
