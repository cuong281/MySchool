package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.*;
import com.jetbrains.grade.exception.LeaveConflictException;
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
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

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
    private final TimeSlotRepository timeSlotRepository;
    private final LeaveRequestRepository leaveRequestRepository;
    private final SecurityAuditService securityAuditService;
    private final ClassScheduleRepository classScheduleRepository;

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

        List<Attendance> records = attendanceRepository.findBySchoolClassIdAndAttendanceDateOrderBySlotNumberAsc(classId, date);
        if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            if (!teacherAssignmentEnforcer.isHomeroomTeacher(currentTeacherId, classId)) {
                java.util.Set<Integer> mySubjectIds = teacherAssignmentEnforcer.getAssignedSubjectIds(currentTeacherId, classId);
                records = records.stream()
                        .filter(a -> a.getSubject() != null && mySubjectIds.contains(a.getSubject().getId()))
                        .toList();
            }
        }

        return records.stream()
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

    @Transactional(readOnly = true)
    public AttendanceSheetDTO getAttendanceSheet(Integer classId, Integer subjectId, Integer slotNumber, LocalDate attendanceDate) {
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Học sinh không có quyền truy cập bảng điểm danh");
        }
        if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            teacherAssignmentEnforcer.assertCanManageAttendance(currentTeacherId, classId, subjectId);
        }

        SchoolClass schoolClass = schoolClassRepository.findById(classId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lớp học với ID: " + classId));

        Subject subject = null;
        if (subjectId != null) {
            subject = subjectRepository.findById(subjectId).orElse(null);
        }

        Optional<TimeSlot> slotOpt = (slotNumber != null)
                ? timeSlotRepository.findBySlotNumberAndIsActiveTrue(slotNumber)
                : Optional.empty();
        if (slotOpt.isEmpty() && slotNumber != null) {
            slotOpt = timeSlotRepository.findBySlotNumber(slotNumber);
        }

        LocalTime startTime = slotOpt.map(TimeSlot::getStartTime).orElse(null);
        LocalTime endTime = slotOpt.map(TimeSlot::getEndTime).orElse(null);

        boolean canEdit = true;
        String lockReason = null;

        LocalDate today = LocalDate.now();
        LocalTime now = LocalTime.now();

        // 1. Kiểm tra lịch học trong thời khóa biểu (ClassSchedule)
        String dayOfWeekName = attendanceDate.getDayOfWeek().name();
        boolean hasSchedule = false;
        try {
            com.jetbrains.grade.model.DayOfWeekVN dayEnum = com.jetbrains.grade.model.DayOfWeekVN.valueOf(dayOfWeekName);
            hasSchedule = (slotNumber != null) && classScheduleRepository.findActiveClassSchedule(classId, dayEnum, slotNumber).isPresent();
        } catch (Exception ignored) {}

        if (!hasSchedule) {
            canEdit = false;
            lockReason = "NO_SCHEDULE";
        } else if (attendanceDate.isAfter(today)) {
            canEdit = false;
            lockReason = "FUTURE_DATE";
        } else if (attendanceDate.isBefore(today)) {
            canEdit = false;
            lockReason = "EXPIRED_PAST_DAY";
        } else if (startTime != null && now.isBefore(startTime)) {
            canEdit = false;
            lockReason = "NOT_STARTED";
        } else {
            canEdit = true;
            lockReason = null;
        }

        List<Student> students = studentRepository.findBySchoolClassIdOrderByFullNameAsc(classId);
        List<Integer> studentIds = students.stream().map(Student::getId).toList();
        List<LeaveRequest> approvedLeaves = studentIds.isEmpty() ? List.of()
                : leaveRequestRepository.findApprovedLeavesByStudentIdsAndDate(studentIds, attendanceDate);
        Map<Integer, LeaveRequest> leaveMap = approvedLeaves.stream()
                .collect(Collectors.toMap(lr -> lr.getStudent().getId(), lr -> lr, (k1, k2) -> k1));

        List<Attendance> existingRecords = (slotNumber != null)
                ? attendanceRepository.findBySchoolClassIdAndAttendanceDateAndSlotNumber(classId, attendanceDate, slotNumber)
                : List.of();
        Map<Integer, Attendance> existingMap = existingRecords.stream()
                .collect(Collectors.toMap(a -> a.getStudent().getId(), a -> a, (k1, k2) -> k1));

        List<AttendanceSheetStudentDTO> studentDTOs = students.stream().map(s -> {
            boolean hasApprovedLeave = leaveMap.containsKey(s.getId());
            LeaveRequest leave = leaveMap.get(s.getId());
            Attendance existing = existingMap.get(s.getId());

            String status;
            String note = null;
            if (existing != null) {
                status = existing.getStatus();
                note = existing.getNote();
            } else if (hasApprovedLeave) {
                status = "EXCUSED_ABSENCE";
            } else {
                status = "PRESENT";
            }

            return AttendanceSheetStudentDTO.builder()
                    .studentId(s.getId())
                    .studentName(s.getFullName())
                    .studentCode(s.getStudentCode())
                    .currentStatus(status)
                    .hasApprovedLeave(hasApprovedLeave)
                    .leaveRequestId(leave != null ? leave.getId() : null)
                    .leaveReason(leave != null ? leave.getReason() : null)
                    .note(note)
                    .build();
        }).toList();

        return AttendanceSheetDTO.builder()
                .classId(schoolClass.getId())
                .className(schoolClass.getClassName())
                .subjectId(subject != null ? subject.getId() : null)
                .subjectName(subject != null ? subject.getSubjectName() : null)
                .slotNumber(slotNumber)
                .startTime(startTime)
                .endTime(endTime)
                .attendanceDate(attendanceDate)
                .canEdit(canEdit)
                .lockReason(lockReason)
                .totalStudents(studentDTOs.size())
                .students(studentDTOs)
                .build();
    }

    @Transactional
    public List<AttendanceRecordDTO> recordBatchAttendance(AttendanceBatchRequest req) {
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Học sinh không có quyền ghi nhận điểm danh");
        }

        if (req.getClassId() == null || req.getAttendanceDate() == null || req.getSlotNumber() == null || req.getItems() == null) {
            throw new IllegalArgumentException("Thiếu thông tin bắt buộc: classId, attendanceDate, slotNumber, items");
        }

        if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            teacherAssignmentEnforcer.assertCanManageAttendance(currentTeacherId, req.getClassId(), req.getSubjectId());
        }

        Optional<TimeSlot> slotOpt = timeSlotRepository.findBySlotNumberAndIsActiveTrue(req.getSlotNumber());
        if (slotOpt.isEmpty()) {
            slotOpt = timeSlotRepository.findBySlotNumber(req.getSlotNumber());
        }
        LocalTime startTime = slotOpt.map(TimeSlot::getStartTime).orElse(null);

        LocalDate today = LocalDate.now();
        LocalTime now = LocalTime.now();

        if (!SecurityUtils.isAdmin()) {
            if (req.getAttendanceDate().isAfter(today)) {
                throw new IllegalArgumentException("Không thể điểm danh cho ngày trong tương lai");
            }
            if (req.getAttendanceDate().isBefore(today)) {
                throw new AccessDeniedException("Hệ thống đã khóa sổ buổi học của các ngày trước đó (chỉ xem)");
            }
            if (startTime != null && now.isBefore(startTime)) {
                throw new IllegalArgumentException("Chưa đến thời gian bắt đầu tiết học (bắt đầu lúc " + startTime + ")");
            }

            // Kiểm tra lịch học trong thời khóa biểu (ClassSchedule)
            String dayOfWeekName = req.getAttendanceDate().getDayOfWeek().name();
            boolean hasSchedule = false;
            try {
                com.jetbrains.grade.model.DayOfWeekVN dayEnum = com.jetbrains.grade.model.DayOfWeekVN.valueOf(dayOfWeekName);
                hasSchedule = classScheduleRepository.findActiveClassSchedule(req.getClassId(), dayEnum, req.getSlotNumber()).isPresent();
            } catch (Exception ignored) {}

            if (!hasSchedule) {
                throw new IllegalArgumentException("Không có lịch học trong thời khóa biểu cho tiết "
                        + req.getSlotNumber() + " vào " + dayOfWeekName + " (" + req.getAttendanceDate() + ")");
            }
        }

        SchoolClass schoolClass = schoolClassRepository.findById(req.getClassId())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lớp học với ID: " + req.getClassId()));

        Subject subject = null;
        if (req.getSubjectId() != null) {
            subject = subjectRepository.findById(req.getSubjectId()).orElse(null);
        }

        Integer currentUserId = SecurityUtils.getCurrentUserId();
        User currentUser = userRepository.findByIdAndIsActiveTrue(currentUserId)
                .orElseThrow(() -> new IllegalArgumentException("Người dùng không tồn tại hoặc bị khóa"));

        List<Integer> studentIds = req.getItems().stream()
                .map(AttendanceBatchItemDTO::getStudentId)
                .filter(Objects::nonNull)
                .toList();
        List<LeaveRequest> approvedLeaves = studentIds.isEmpty() ? List.of()
                : leaveRequestRepository.findApprovedLeavesByStudentIdsAndDate(studentIds, req.getAttendanceDate());
        Map<Integer, LeaveRequest> leaveMap = approvedLeaves.stream()
                .collect(Collectors.toMap(lr -> lr.getStudent().getId(), lr -> lr, (k1, k2) -> k1));

        List<Attendance> existingRecords = attendanceRepository.findBySchoolClassIdAndAttendanceDateAndSlotNumber(
                req.getClassId(), req.getAttendanceDate(), req.getSlotNumber());
        Map<Integer, Attendance> existingMap = existingRecords.stream()
                .collect(Collectors.toMap(a -> a.getStudent().getId(), a -> a, (k1, k2) -> k1));

        Map<Integer, Student> studentMap = studentRepository.findBySchoolClassId(req.getClassId()).stream()
                .collect(Collectors.toMap(Student::getId, s -> s));

        // Pass 1: Validate items and Check Approved Leave Conflicts
        for (AttendanceBatchItemDTO item : req.getItems()) {
            if (item.getStudentId() == null || item.getStatus() == null) {
                throw new IllegalArgumentException("Mỗi học sinh phải có studentId và status");
            }
            Student student = studentMap.get(item.getStudentId());
            if (student == null) {
                throw new IllegalArgumentException("Học sinh với ID " + item.getStudentId() + " không thuộc lớp này");
            }

            String normStatus = item.getStatus().trim().toUpperCase();
            if (!List.of("PRESENT", "EXCUSED_ABSENCE", "UNEXCUSED_ABSENCE", "LATE").contains(normStatus)) {
                throw new IllegalArgumentException("Trạng thái không hợp lệ: " + item.getStatus());
            }

            if (leaveMap.containsKey(item.getStudentId())) {
                LeaveRequest leave = leaveMap.get(item.getStudentId());
                if (!"EXCUSED_ABSENCE".equals(normStatus)) {
                    if (Boolean.TRUE.equals(item.getOverrideLeave())) {
                        String reason = item.getOverrideReason();
                        if (reason == null || reason.trim().length() < 3 || reason.trim().length() > 150) {
                            throw new LeaveConflictException(
                                    student.getId(),
                                    leave.getId(),
                                    student.getFullName(),
                                    student.getStudentCode(),
                                    String.format("Học sinh [%s - %s] đã có đơn xin nghỉ phép được duyệt. Vui lòng cung cấp lý do ghi đè hợp lệ từ 3 đến 150 ký tự.",
                                            student.getFullName(), student.getStudentCode())
                            );
                        }
                    } else {
                        throw new LeaveConflictException(
                                student.getId(),
                                leave.getId(),
                                student.getFullName(),
                                student.getStudentCode(),
                                String.format("Học sinh [%s - %s] đã có đơn xin nghỉ phép được duyệt. Vui lòng xác nhận ghi đè và cung cấp lý do.",
                                        student.getFullName(), student.getStudentCode())
                        );
                    }
                }
            }
        }

        // Pass 2: Persist / Update
        List<Attendance> toSave = new ArrayList<>();
        List<AttendanceRecordDTO> resultDTOs = new ArrayList<>();

        for (AttendanceBatchItemDTO item : req.getItems()) {
            Student student = studentMap.get(item.getStudentId());
            String normStatus = item.getStatus().trim().toUpperCase();
            Attendance attendance = existingMap.get(item.getStudentId());

            String finalNote = item.getNote();
            boolean isOverridden = false;
            if (leaveMap.containsKey(item.getStudentId()) && !"EXCUSED_ABSENCE".equals(normStatus) && Boolean.TRUE.equals(item.getOverrideLeave())) {
                LeaveRequest leave = leaveMap.get(item.getStudentId());
                finalNote = String.format("[GHI ĐÈ ĐƠN NGHỈ #%d] Lý do: %s", leave.getId(), item.getOverrideReason().trim());
                isOverridden = true;
            }

            if (attendance != null) {
                // UPDATE: PRESERVE original RecordedByUserID
                attendance.setStatus(normStatus);
                attendance.setNote(finalNote);
                attendance.setUpdatedAt(LocalDateTime.now());
                toSave.add(attendance);

                securityAuditService.logSecurityEvent(
                        isOverridden ? "OVERRIDE_APPROVED_LEAVE" : "UPDATE_ATTENDANCE",
                        currentUser.getId(),
                        currentUser.getUsername(),
                        SecurityUtils.getCurrentRoles(),
                        "Attendance:ID=" + attendance.getId() + ":Student=" + student.getId() + ":Slot=" + req.getSlotNumber(),
                        "SUCCESS",
                        isOverridden ? finalNote : ("Updated status to " + normStatus)
                );
            } else {
                // CREATE: Record current user
                Attendance newAttendance = new Attendance();
                newAttendance.setStudent(student);
                newAttendance.setSchoolClass(schoolClass);
                newAttendance.setSubject(subject);
                newAttendance.setAttendanceDate(req.getAttendanceDate());
                newAttendance.setSlotNumber(req.getSlotNumber());
                newAttendance.setStatus(normStatus);
                newAttendance.setNote(finalNote);
                newAttendance.setRecordedBy(currentUser);
                newAttendance.setCreatedAt(LocalDateTime.now());
                newAttendance.setUpdatedAt(LocalDateTime.now());
                toSave.add(newAttendance);

                if (isOverridden) {
                    securityAuditService.logSecurityEvent(
                            "OVERRIDE_APPROVED_LEAVE",
                            currentUser.getId(),
                            currentUser.getUsername(),
                            SecurityUtils.getCurrentRoles(),
                            "Attendance:Student=" + student.getId() + ":Slot=" + req.getSlotNumber(),
                            "SUCCESS",
                            finalNote
                    );
                }
            }
        }

        List<Attendance> savedList = attendanceRepository.saveAll(toSave);

        // Notifications
        for (Attendance a : savedList) {
            if (a.getStudent() != null && a.getStudent().getUser() != null &&
                    ("UNEXCUSED_ABSENCE".equals(a.getStatus()) || "LATE".equals(a.getStatus()))) {
                try {
                    String statusLabel = "UNEXCUSED_ABSENCE".equals(a.getStatus()) ? "Vắng không phép" : "Đi muộn";
                    notificationService.createNotification(
                            a.getStudent().getUser(),
                            "Cảnh báo điểm danh",
                            String.format("Bạn đã bị ghi nhận %s vào ngày %s (Tiết %s).",
                                    statusLabel, a.getAttendanceDate(), a.getSlotNumber() != null ? a.getSlotNumber() : 1),
                            "ATTENDANCE_ALERT",
                            a.getId()
                    );
                } catch (Exception e) {
                    log.warn("Failed to trigger attendance notification for student {}: {}", a.getStudent().getId(), e.getMessage());
                }
            }
            resultDTOs.add(mapToDTO(a));
        }

        return resultDTOs;
    }

    @Transactional(readOnly = true)
    public AttendanceClassHistoryDTO getClassAttendanceHistory(Integer classId, LocalDate startDate, LocalDate endDate) {
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Học sinh không có quyền xem lịch sử điểm danh");
        }
        if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            teacherAssignmentEnforcer.assertCanViewClassAttendance(currentTeacherId, classId);
        }

        SchoolClass schoolClass = schoolClassRepository.findById(classId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lớp học với ID: " + classId));

        List<Attendance> records;
        if (startDate != null && endDate != null) {
            records = attendanceRepository.findBySchoolClassIdAndAttendanceDateBetweenOrderByAttendanceDateDescSlotNumberDesc(classId, startDate, endDate);
        } else {
            records = attendanceRepository.findBySchoolClassIdOrderByAttendanceDateDescSlotNumberDesc(classId);
        }

        Integer currentTeacherId = SecurityUtils.isAdmin() ? null : SecurityUtils.getCurrentTeacherId();
        boolean isHomeroom = currentTeacherId != null && teacherAssignmentEnforcer.isHomeroomTeacher(currentTeacherId, classId);
        java.util.Set<Integer> mySubjectIds = java.util.Collections.emptySet();
        if (!SecurityUtils.isAdmin() && !isHomeroom) {
            mySubjectIds = teacherAssignmentEnforcer.getAssignedSubjectIds(currentTeacherId, classId);
            final java.util.Set<Integer> allowedSubjects = mySubjectIds;
            records = records.stream()
                    .filter(a -> a.getSubject() != null && allowedSubjects.contains(a.getSubject().getId()))
                    .toList();
        }

        Map<Integer, TimeSlot> slotMap = timeSlotRepository.findByIsActiveTrueOrderBySlotNumberAsc().stream()
                .collect(Collectors.toMap(TimeSlot::getSlotNumber, ts -> ts, (k1, k2) -> k1));

        // Group by (date, slot, subject)
        Map<String, List<Attendance>> sessionGroups = new LinkedHashMap<>();
        for (Attendance a : records) {
            String key = a.getAttendanceDate() + "_" + a.getSlotNumber() + "_" + (a.getSubject() != null ? a.getSubject().getId() : 0);
            sessionGroups.computeIfAbsent(key, k -> new ArrayList<>()).add(a);
        }

        LocalDate today = LocalDate.now();
        LocalTime now = LocalTime.now();

        List<com.jetbrains.grade.model.ClassSchedule> classSchedules = classScheduleRepository.findBySchoolClassIdWithDetails(classId);
        Set<String> scheduledSlots = classSchedules.stream()
                .filter(cs -> "ACTIVE".equalsIgnoreCase(cs.getStatus()))
                .map(cs -> cs.getDayOfWeek().name() + "_" + cs.getTimeSlot().getSlotNumber())
                .collect(Collectors.toSet());

        List<AttendanceSessionSummaryDTO> sessionSummaries = new ArrayList<>();
        int totalPresent = 0;
        int totalExcused = 0;
        int totalUnexcused = 0;
        int totalLate = 0;

        for (Map.Entry<String, List<Attendance>> entry : sessionGroups.entrySet()) {
            List<Attendance> group = entry.getValue();
            if (group.isEmpty()) continue;
            Attendance first = group.get(0);
            LocalDate sessDate = first.getAttendanceDate();
            Integer slotNum = first.getSlotNumber();
            Subject subj = first.getSubject();

            int pres = 0;
            int exc = 0;
            int unexc = 0;
            int late = 0;
            List<String> absentStudents = new ArrayList<>();

            for (Attendance a : group) {
                String st = a.getStatus();
                if ("PRESENT".equals(st)) pres++;
                else if ("EXCUSED_ABSENCE".equals(st)) {
                    exc++;
                    absentStudents.add(a.getStudent().getFullName() + " (Có phép)");
                } else if ("UNEXCUSED_ABSENCE".equals(st)) {
                    unexc++;
                    absentStudents.add(a.getStudent().getFullName() + " (Không phép)");
                } else if ("LATE".equals(st)) {
                    late++;
                }
            }

            totalPresent += pres;
            totalExcused += exc;
            totalUnexcused += unexc;
            totalLate += late;

            // Kiểm tra: Phải có lịch học trong thời khóa biểu + chỉ điểm danh trong ngày + đến tiết mới được điểm danh
            String dayOfWeekName = sessDate.getDayOfWeek().name();
            boolean hasSchedule = scheduledSlots.contains(dayOfWeekName + "_" + slotNum);

            boolean canEdit = true;
            if (!hasSchedule) {
                canEdit = false;
            } else if (sessDate.isBefore(today) || sessDate.isAfter(today)) {
                canEdit = false;
            } else {
                TimeSlot slot = slotMap.get(slotNum);
                if (slot != null && slot.getStartTime() != null && now.isBefore(slot.getStartTime())) {
                    canEdit = false;
                }
            }

            if (!SecurityUtils.isAdmin() && !isHomeroom) {
                if (subj == null || !mySubjectIds.contains(subj.getId())) {
                    canEdit = false;
                }
            }

            sessionSummaries.add(AttendanceSessionSummaryDTO.builder()
                    .attendanceDate(sessDate)
                    .slotNumber(slotNum)
                    .subjectId(subj != null ? subj.getId() : null)
                    .subjectName(subj != null ? subj.getSubjectName() : null)
                    .presentCount(pres)
                    .excusedCount(exc)
                    .unexcusedCount(unexc)
                    .lateCount(late)
                    .totalCount(group.size())
                    .canEdit(canEdit)
                    .absentStudents(absentStudents)
                    .build());
        }

        int totalAll = totalPresent + totalExcused + totalUnexcused + totalLate;
        double overallRate = totalAll == 0 ? 100.0 :
                Math.round(((totalPresent * 1.0 + totalExcused * 0.8 + totalLate * 0.5) / (totalAll * 1.0) * 100.0) * 10.0) / 10.0;

        // In-memory student summaries calculation (Zero N+1 query)
        List<Student> classStudents = studentRepository.findBySchoolClassIdOrderByFullNameAsc(classId);
        Map<Integer, List<Attendance>> studentRecords = records.stream()
                .collect(Collectors.groupingBy(a -> a.getStudent().getId()));

        List<AttendanceStudentSummaryDTO> studentSummaries = new ArrayList<>();
        List<AttendanceAtRiskStudentDTO> atRisk = new ArrayList<>();

        for (Student s : classStudents) {
            List<Attendance> sList = studentRecords.getOrDefault(s.getId(), List.of());
            int unexc = 0;
            int exc = 0;
            int lat = 0;
            int pr = 0;
            List<AttendanceRecordDTO> sRecordDTOs = new ArrayList<>();

            for (Attendance a : sList) {
                String st = a.getStatus();
                if ("PRESENT".equals(st)) pr++;
                else if ("EXCUSED_ABSENCE".equals(st)) exc++;
                else if ("UNEXCUSED_ABSENCE".equals(st)) unexc++;
                else if ("LATE".equals(st)) lat++;
                sRecordDTOs.add(mapToDTO(a));
            }

            int sTotal = unexc + exc + lat + pr;
            // Standard individual rate: (Present / Actually Tracked Sessions) * 100%
            // Avoid dividing by class total sessions to correctly handle new students who transferred mid-semester
            double sRate = sTotal == 0 ? 100.0 :
                    Math.round(((pr * 1.0) / (sTotal * 1.0) * 100.0) * 10.0) / 10.0;

            boolean isCritical = unexc >= 3 || sRate < 70.0;
            boolean isWarning = unexc >= 1 || lat >= 3 || sRate < 85.0;

            String warningNote = "Chuyên cần tốt";
            if (isCritical) {
                warningNote = "Nguy cơ cấm thi";
            } else if (isWarning) {
                warningNote = "Cảnh báo chuyên cần";
            }

            if (unexc >= 2 || sRate < 85.0) {
                atRisk.add(AttendanceAtRiskStudentDTO.builder()
                        .studentId(s.getId())
                        .studentName(s.getFullName())
                        .studentCode(s.getStudentCode())
                        .unexcusedCount(unexc)
                        .rate(sRate)
                        .warningNote(warningNote)
                        .build());
            }

            studentSummaries.add(AttendanceStudentSummaryDTO.builder()
                    .studentId(s.getId())
                    .studentName(s.getFullName())
                    .studentCode(s.getStudentCode())
                    .presentCount(pr)
                    .excusedCount(exc)
                    .unexcusedCount(unexc)
                    .lateCount(lat)
                    .totalTrackedSessions(sTotal)
                    .attendanceRate(sRate)
                    .isAtRisk(isCritical || isWarning)
                    .warningNote(warningNote)
                    .records(sRecordDTOs)
                    .build());
        }

        return AttendanceClassHistoryDTO.builder()
                .classId(schoolClass.getId())
                .className(schoolClass.getClassName())
                .totalStudents(classStudents.size())
                .attendanceRate(overallRate)
                .totalSessions(sessionSummaries.size())
                .presentCount(totalPresent)
                .excusedCount(totalExcused)
                .unexcusedCount(totalUnexcused)
                .lateCount(totalLate)
                .sessions(sessionSummaries)
                .atRiskStudents(atRisk)
                .studentSummaries(studentSummaries)
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
