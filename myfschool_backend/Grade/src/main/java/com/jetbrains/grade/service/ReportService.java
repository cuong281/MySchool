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
        if (!SecurityUtils.isAdmin()) {
            throw new AccessDeniedException("Chỉ quản trị viên mới có quyền xem báo cáo toàn trường");
        }

        long totalStudents = studentRepository.count();
        long totalTeachers = teacherRepository.count();
        long totalClasses = schoolClassRepository.count();

        List<Grade> grades = gradeRepository.findAll();
        long totalGrades = grades.size();

        double avgGpa = grades.stream()
                .filter(g -> g.getAverageScore() != null)
                .mapToDouble(Grade::getAverageScore)
                .average()
                .orElse(0.0);
        avgGpa = round(avgGpa, 2);

        Map<String, Long> gradeDist = grades.stream()
                .filter(g -> g.getLetterGrade() != null && !g.getLetterGrade().isBlank())
                .collect(Collectors.groupingBy(Grade::getLetterGrade, Collectors.counting()));

        List<Attendance> attendances = attendanceRepository.findAll();
        long totalAttendance = attendances.size();
        long presentCount = attendances.stream().filter(a -> "PRESENT".equalsIgnoreCase(a.getStatus())).count();
        long excusedCount = attendances.stream().filter(a -> "EXCUSED_ABSENCE".equalsIgnoreCase(a.getStatus())).count();
        long unexcusedCount = attendances.stream().filter(a -> "UNEXCUSED_ABSENCE".equalsIgnoreCase(a.getStatus())).count();
        long lateCount = attendances.stream().filter(a -> "LATE".equalsIgnoreCase(a.getStatus())).count();

        double attendanceRate = totalAttendance > 0
                ? round((presentCount * 100.0) / totalAttendance, 2)
                : 100.0;

        List<LeaveRequest> leaveRequests = leaveRequestRepository.findAll();
        long totalLeaves = leaveRequests.size();
        long pendingLeaves = leaveRequests.stream().filter(l -> "Chờ duyệt".equalsIgnoreCase(l.getStatus())).count();
        long approvedLeaves = leaveRequests.stream().filter(l -> "APPROVED".equalsIgnoreCase(l.getStatus()) || "Đã duyệt".equalsIgnoreCase(l.getStatus())).count();
        long rejectedLeaves = leaveRequests.stream().filter(l -> "REJECTED".equalsIgnoreCase(l.getStatus()) || "Từ chối".equalsIgnoreCase(l.getStatus())).count();

        return AdminDashboardDTO.builder()
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

        SchoolClass homeroomClass = homeroomClasses.get(0);
        Integer classId = homeroomClass.getId();

        long totalStudents = studentRepository.countBySchoolClassId(classId);

        List<LeaveRequest> classLeaves = leaveRequestRepository.findByClassIdsOrderByCreatedAtDesc(List.of(classId));
        long totalLeaves = classLeaves.size();
        long pendingLeaves = classLeaves.stream().filter(l -> "Chờ duyệt".equalsIgnoreCase(l.getStatus())).count();

        List<Attendance> classAttendances = attendanceRepository.findBySchoolClassId(classId);
        long totalAttendance = classAttendances.size();
        long presentCount = classAttendances.stream().filter(a -> "PRESENT".equalsIgnoreCase(a.getStatus())).count();
        long excusedCount = classAttendances.stream().filter(a -> "EXCUSED_ABSENCE".equalsIgnoreCase(a.getStatus())).count();
        long unexcusedCount = classAttendances.stream().filter(a -> "UNEXCUSED_ABSENCE".equalsIgnoreCase(a.getStatus())).count();
        long lateCount = classAttendances.stream().filter(a -> "LATE".equalsIgnoreCase(a.getStatus())).count();

        double attendanceRate = totalAttendance > 0
                ? round((presentCount * 100.0) / totalAttendance, 2)
                : 100.0;

        List<Grade> classGrades = gradeRepository.findByStudentSchoolClassId(classId);
        double avgGpa = classGrades.stream()
                .filter(g -> g.getAverageScore() != null)
                .mapToDouble(Grade::getAverageScore)
                .average()
                .orElse(0.0);
        avgGpa = round(avgGpa, 2);

        Map<String, Long> gradeDist = classGrades.stream()
                .filter(g -> g.getLetterGrade() != null && !g.getLetterGrade().isBlank())
                .collect(Collectors.groupingBy(Grade::getLetterGrade, Collectors.counting()));

        return TeacherHomeroomDashboardDTO.builder()
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
