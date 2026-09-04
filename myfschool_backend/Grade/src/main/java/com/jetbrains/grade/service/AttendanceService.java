package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.AttendanceCreateRequest;
import com.jetbrains.grade.dto.AttendanceRecordDTO;
import com.jetbrains.grade.dto.AttendanceSummaryDTO;
import com.jetbrains.grade.model.*;
import com.jetbrains.grade.repository.*;
import com.jetbrains.grade.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class AttendanceService {

    private final AttendanceRepository attendanceRepository;
    private final StudentRepository studentRepository;
    private final SchoolClassRepository schoolClassRepository;
    private final SubjectRepository subjectRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final com.jetbrains.grade.security.TeacherAssignmentEnforcer teacherAssignmentEnforcer;

    @Transactional
    public AttendanceRecordDTO recordAttendance(AttendanceCreateRequest req) {
        // Enforce RBAC: Only Teacher or Admin can record attendance
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Hoc sinh khong co quyen ghi nhan diem danh");
        }

        if (req.getStudentId() == null || req.getClassId() == null || req.getAttendanceDate() == null || req.getStatus() == null) {
            throw new IllegalArgumentException("Thieu thong tin bat buoc: studentId, classId, attendanceDate, status");
        }

        Student student = studentRepository.findById(req.getStudentId())
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay hoc sinh voi ID: " + req.getStudentId()));

        SchoolClass schoolClass = schoolClassRepository.findById(req.getClassId())
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay lop hoc voi ID: " + req.getClassId()));

        if (student.getSchoolClass() == null || !student.getSchoolClass().getId().equals(req.getClassId())) {
            throw new IllegalArgumentException("Hoc sinh khong thuoc lop hoc nay");
        }

        if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            teacherAssignmentEnforcer.assertCanManageAttendance(currentTeacherId, req.getClassId(), req.getSubjectId());
        }

        Subject subject = null;
        if (req.getSubjectId() != null) {
            subject = subjectRepository.findById(req.getSubjectId()).orElse(null);
        }

        Integer currentUserId = SecurityUtils.getCurrentUserId();
        User recordedBy = userRepository.findByIdAndIsActiveTrue(currentUserId)
                .orElseThrow(() -> new IllegalArgumentException("Nguoi thuc hien khong ton tai hoac bi khoa"));

        // Normalize status
        String normalizedStatus = req.getStatus().toUpperCase();
        if (!List.of("PRESENT", "EXCUSED_ABSENCE", "UNEXCUSED_ABSENCE", "LATE").contains(normalizedStatus)) {
            throw new IllegalArgumentException("Trang thai khong hop le: " + req.getStatus());
        }

        Attendance attendance;
        if (req.getSlotNumber() != null) {
            var existingOpt = attendanceRepository.findByStudentIdAndAttendanceDateAndSlotNumber(
                    student.getId(), req.getAttendanceDate(), req.getSlotNumber());
            if (existingOpt.isPresent()) {
                attendance = existingOpt.get();
                attendance.setStatus(normalizedStatus);
                attendance.setNote(req.getNote());
                attendance.setRecordedBy(recordedBy);
                attendance.setUpdatedAt(LocalDateTime.now());
            } else {
                attendance = createNewAttendance(student, schoolClass, subject, req, normalizedStatus, recordedBy);
            }
        } else {
            attendance = createNewAttendance(student, schoolClass, subject, req, normalizedStatus, recordedBy);
        }

        Attendance saved = attendanceRepository.save(attendance);

        // Best-effort Trigger Notification if unexcused or late
        if (student.getUser() != null && ("UNEXCUSED_ABSENCE".equals(normalizedStatus) || "LATE".equals(normalizedStatus))) {
            try {
                String statusLabel = "UNEXCUSED_ABSENCE".equals(normalizedStatus) ? "Vắng không phép" : "Đi muộn";
                notificationService.createNotification(
                        student.getUser(),
                        "Cảnh báo điểm danh",
                        String.format("Bạn đã bị ghi nhận %s vào ngày %s (Tiết %s).",
                                statusLabel, req.getAttendanceDate(), req.getSlotNumber() != null ? req.getSlotNumber() : 1),
                        "ATTENDANCE_ALERT",
                        saved.getId()
                );
            } catch (Exception e) {
                log.warn("Failed to trigger attendance notification: {}", e.getMessage());
            }
        }

        return mapToDTO(saved);
    }

    private Attendance createNewAttendance(
            Student student, SchoolClass schoolClass, Subject subject,
            AttendanceCreateRequest req, String normalizedStatus, User recordedBy) {
        Attendance attendance = new Attendance();
        attendance.setStudent(student);
        attendance.setSchoolClass(schoolClass);
        attendance.setSubject(subject);
        attendance.setAttendanceDate(req.getAttendanceDate());
        attendance.setSlotNumber(req.getSlotNumber());
        attendance.setStatus(normalizedStatus);
        attendance.setNote(req.getNote());
        attendance.setRecordedBy(recordedBy);
        attendance.setCreatedAt(LocalDateTime.now());
        attendance.setUpdatedAt(LocalDateTime.now());
        return attendance;
    }

    @Transactional(readOnly = true)
    public List<AttendanceRecordDTO> getMyAttendance() {
        Integer currentStudentId = SecurityUtils.getCurrentStudentId();
        if (currentStudentId == null) {
            return List.of();
        }
        return attendanceRepository.findByStudentIdOrderByAttendanceDateDesc(currentStudentId).stream()
                .map(this::mapToDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public AttendanceSummaryDTO getMyAttendanceSummary() {
        Integer currentStudentId = SecurityUtils.getCurrentStudentId();
        if (currentStudentId == null) {
            throw new AccessDeniedException("Khong tim thay thong tin hoc sinh cho tai khoan nay");
        }
        return calculateSummary(currentStudentId);
    }

    @Transactional(readOnly = true)
    public List<AttendanceRecordDTO> getStudentAttendance(Integer studentId) {
        // Enforce ownership: student can only query own studentId
        if (SecurityUtils.isStudent()) {
            Integer currentStudentId = SecurityUtils.getCurrentStudentId();
            if (!studentId.equals(currentStudentId)) {
                throw new AccessDeniedException("Ban khong co quyen xem diem danh cua hoc sinh khac");
            }
        } else if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            Student student = studentRepository.findById(studentId)
                    .orElseThrow(() -> new IllegalArgumentException("Khong tim thay hoc sinh voi ID: " + studentId));
            teacherAssignmentEnforcer.assertCanViewStudentData(currentTeacherId, student);
        }

        return attendanceRepository.findByStudentIdOrderByAttendanceDateDesc(studentId).stream()
                .map(this::mapToDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public AttendanceSummaryDTO getStudentAttendanceSummary(Integer studentId) {
        // Enforce ownership: student can only query own studentId
        if (SecurityUtils.isStudent()) {
            Integer currentStudentId = SecurityUtils.getCurrentStudentId();
            if (!studentId.equals(currentStudentId)) {
                throw new AccessDeniedException("Ban khong co quyen xem chuyen can cua hoc sinh khac");
            }
        } else if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            Student student = studentRepository.findById(studentId)
                    .orElseThrow(() -> new IllegalArgumentException("Khong tim thay hoc sinh voi ID: " + studentId));
            teacherAssignmentEnforcer.assertCanViewStudentData(currentTeacherId, student);
        }

        return calculateSummary(studentId);
    }

    @Transactional(readOnly = true)
    public List<AttendanceRecordDTO> getClassAttendance(Integer classId, LocalDate date) {
        // Students cannot view class-wide attendance
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Hoc sinh khong co quyen xem diem danh cua ca lop");
        }
        if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            teacherAssignmentEnforcer.assertCanViewClassAttendance(currentTeacherId, classId);
        }

        return attendanceRepository.findBySchoolClassIdAndAttendanceDateOrderBySlotNumberAsc(classId, date).stream()
                .map(this::mapToDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public AttendanceSummaryDTO calculateSummary(Integer studentId) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay hoc sinh voi ID: " + studentId));

        long present = attendanceRepository.countByStudentIdAndStatus(studentId, "PRESENT");
        long excused = attendanceRepository.countByStudentIdAndStatus(studentId, "EXCUSED_ABSENCE");
        long unexcused = attendanceRepository.countByStudentIdAndStatus(studentId, "UNEXCUSED_ABSENCE");
        long late = attendanceRepository.countByStudentIdAndStatus(studentId, "LATE");
        long total = present + excused + unexcused + late;

        // Formula: Present 1.0, Excused 0.8, Late 0.5, Unexcused 0.0
        double rate = total == 0 ? 100.0 :
                Math.round(((present * 1.0 + excused * 0.8 + late * 0.5) / (total * 1.0) * 100.0) * 10.0) / 10.0;

        String note = "Chuyên cần tốt";
        if (unexcused >= 3 || rate < 70.0) {
            note = "Nguy cơ cấm thi";
        } else if (unexcused >= 1 || late >= 3 || rate < 85.0) {
            note = "Cảnh báo vắng học";
        }

        return AttendanceSummaryDTO.builder()
                .studentId(student.getId())
                .studentName(student.getFullName())
                .studentCode(student.getStudentCode())
                .className(student.getSchoolClass() != null ? student.getSchoolClass().getClassName() : "")
                .totalSessions(total)
                .presentCount(present)
                .excusedAbsentCount(excused)
                .unexcusedAbsentCount(unexcused)
                .lateCount(late)
                .attendanceRate(rate)
                .statusNote(note)
                .build();
    }

    private AttendanceRecordDTO mapToDTO(Attendance a) {
        return AttendanceRecordDTO.builder()
                .id(a.getId())
                .studentId(a.getStudent() != null ? a.getStudent().getId() : null)
                .studentName(a.getStudent() != null ? a.getStudent().getFullName() : "")
                .studentCode(a.getStudent() != null ? a.getStudent().getStudentCode() : "")
                .classId(a.getSchoolClass() != null ? a.getSchoolClass().getId() : null)
                .className(a.getSchoolClass() != null ? a.getSchoolClass().getClassName() : "")
                .subjectId(a.getSubject() != null ? a.getSubject().getId() : null)
                .subjectName(a.getSubject() != null ? a.getSubject().getSubjectName() : "")
                .attendanceDate(a.getAttendanceDate())
                .slotNumber(a.getSlotNumber())
                .status(a.getStatus())
                .note(a.getNote())
                .recordedByName(a.getRecordedBy() != null ? a.getRecordedBy().getUsername() : "")
                .build();
    }
}
