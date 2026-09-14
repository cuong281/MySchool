package com.jetbrains.grade.service;

import com.jetbrains.grade.model.LeaveRequest;
import com.jetbrains.grade.model.LeaveRequestStatusHistory;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.model.Teacher;
import com.jetbrains.grade.model.User;
import com.jetbrains.grade.repository.LeaveRequestRepository;
import com.jetbrains.grade.repository.LeaveRequestStatusHistoryRepository;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.repository.TeacherRepository;
import com.jetbrains.grade.repository.UserRepository;
import com.jetbrains.grade.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class LeaveRequestService {

    private final LeaveRequestRepository leaveRequestRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final UserRepository userRepository;
    private final LeaveRequestStatusHistoryRepository historyRepository;
    private final NotificationService notificationService;
    private final com.jetbrains.grade.security.TeacherAssignmentEnforcer teacherAssignmentEnforcer;
    private final SecurityAuditService auditService;

    @Transactional
    public LeaveRequest create(LeaveRequest request) {
        Integer currentUserId = SecurityUtils.getCurrentUserId();

        if (SecurityUtils.isStudent()) {
            Student currentStudent = studentRepository.findByUserId(currentUserId)
                    .orElseThrow(() -> new IllegalArgumentException("Khong tim thay thong tin hoc sinh cho tai khoan nay"));

            // Enforce ownership: student can only create leave request for themselves
            if (request.getStudent() != null && request.getStudent().getId() != null
                    && !request.getStudent().getId().equals(currentStudent.getId())) {
                throw new AccessDeniedException("Hoc sinh khong the tao don xin phep thay cho nguoi khac");
            }
            request.setStudent(currentStudent);
            request.setTeacher(null);
            if (request.getRequestType() == null || request.getRequestType().isBlank()) {
                request.setRequestType("Nghỉ học");
            }
        } else if (SecurityUtils.isTeacher()) {
            Teacher currentTeacher = teacherRepository.findByUserId(currentUserId)
                    .orElseThrow(() -> new IllegalArgumentException("Khong tim thay thong tin giao vien cho tai khoan nay"));

            // Enforce ownership: teacher can only create leave request for themselves
            if (request.getTeacher() != null && request.getTeacher().getId() != null
                    && !request.getTeacher().getId().equals(currentTeacher.getId())) {
                throw new AccessDeniedException("Giao vien khong the tao don xin phep thay cho nguoi khac");
            }
            request.setTeacher(currentTeacher);
            request.setStudent(null);
            if (request.getRequestType() == null || request.getRequestType().isBlank()) {
                request.setRequestType("Nghỉ phép");
            }
        } else if (!SecurityUtils.isAdmin()) {
            throw new AccessDeniedException("Ban khong co quyen tao don xin phep");
        }

        if (request.getFromDate() == null || request.getToDate() == null) {
            throw new IllegalArgumentException("Vui lòng chọn đầy đủ ngày bắt đầu và ngày kết thúc");
        }

        if (request.getFromDate().isAfter(request.getToDate())) {
            throw new IllegalArgumentException("Ngày bắt đầu không được sau ngày kết thúc");
        }

        if (request.getReason() == null || request.getReason().trim().length() < 3) {
            throw new IllegalArgumentException("Lý do xin nghỉ không được để trống và phải có ít nhất 3 ký tự");
        }

        request.setId(null);
        request.setStatus("Chờ duyệt");
        request.setCreatedAt(LocalDateTime.now());
        request.setUpdatedAt(LocalDateTime.now());
        return leaveRequestRepository.save(request);
    }

    public List<LeaveRequest> getByUserId(Integer userId) {
        // Enforce ownership check at Service layer for students
        if (SecurityUtils.isStudent()) {
            Integer currentUserId = SecurityUtils.getCurrentUserId();
            if (!userId.equals(currentUserId)) {
                throw new AccessDeniedException("Ban khong co quyen xem don xin phep cua hoc sinh khac");
            }
        }

        var studentOpt = studentRepository.findByUserId(userId);
        if (studentOpt.isPresent()) {
            Student student = studentOpt.get();
            if (!SecurityUtils.isAdmin() && !SecurityUtils.isStudent()) {
                Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
                teacherAssignmentEnforcer.assertCanViewStudentData(currentTeacherId, student);
            }
            return leaveRequestRepository.findByStudentIdOrderByCreatedAtDesc(student.getId());
        }

        var teacherOpt = teacherRepository.findByUserId(userId);
        if (teacherOpt.isPresent()) {
            Teacher teacher = teacherOpt.get();
            if (!SecurityUtils.isAdmin()) {
                Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
                if (currentTeacherId == null || !currentTeacherId.equals(teacher.getId())) {
                    throw new AccessDeniedException("Ban khong co quyen xem don xin phep cua giao vien khac");
                }
            }
            return leaveRequestRepository.findByTeacherIdOrderByCreatedAtDesc(teacher.getId());
        }

        return List.of();
    }

    public List<LeaveRequest> getMyLeaveRequests() {
        Integer currentUserId = SecurityUtils.getCurrentUserId();
        return getByUserId(currentUserId);
    }

    public List<LeaveRequest> getAll() {
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Hoc sinh khong co quyen xem danh sach don xin phep toan truong");
        }
        if (SecurityUtils.isAdmin()) {
            return leaveRequestRepository.findAll();
        }
        // For Teacher: only return leave requests for classes where teacher is homeroom teacher
        Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
        if (currentTeacherId == null) {
            throw new AccessDeniedException("Khong tim thay thong tin giao vien hop le");
        }
        return leaveRequestRepository.findByStudentSchoolClassHomeroomTeacherIdOrderByCreatedAtDesc(currentTeacherId);
    }

    @Transactional
    public LeaveRequest updateStatus(Integer id, String newStatus, String adminNote) {
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Hoc sinh khong co quyen duyet hoac tu choi don xin phep");
        }

        LeaveRequest request = leaveRequestRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay don voi ID: " + id));

        if (request.getTeacher() != null) {
            // Teacher leave requests can ONLY be processed by Admin
            if (!SecurityUtils.isAdmin()) {
                throw new AccessDeniedException("Chi quan tri vien moi co quyen duyet don xin phep cua giao vien");
            }
        } else if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            teacherAssignmentEnforcer.assertCanProcessLeaveRequest(currentTeacherId, request);
        }

        Integer currentUserId = SecurityUtils.getCurrentUserId();
        User processedBy = userRepository.findByIdAndIsActiveTrue(currentUserId)
                .orElseThrow(() -> new RuntimeException("Processed by user not found or inactive"));

        String oldStatus = request.getStatus();
        request.setStatus(newStatus);
        request.setProcessedBy(processedBy);
        request.setProcessedAt(LocalDateTime.now());
        request.setAdminNote(adminNote);
        request.setUpdatedAt(LocalDateTime.now());

        LeaveRequest updated = leaveRequestRepository.save(request);

        LeaveRequestStatusHistory history = new LeaveRequestStatusHistory();
        history.setLeaveRequest(updated);
        history.setChangedBy(processedBy);
        history.setOldStatus(oldStatus);
        history.setNewStatus(newStatus);
        history.setNote(adminNote);
        history.setChangedAt(LocalDateTime.now());
        historyRepository.save(history);

        // Trigger notification to requester (student or teacher)
        User targetUser = null;
        if (updated.getStudent() != null && updated.getStudent().getUser() != null) {
            targetUser = updated.getStudent().getUser();
        } else if (updated.getTeacher() != null && updated.getTeacher().getUser() != null) {
            targetUser = updated.getTeacher().getUser();
        }

        if (targetUser != null) {
            try {
                notificationService.createNotification(
                        targetUser,
                        "Cập nhật đơn xin nghỉ",
                        "Đơn xin nghỉ của bạn đã được chuyển sang trạng thái: " + newStatus,
                        "LEAVE_REQUEST_STATUS",
                        updated.getId()
                );
            } catch (Exception e) {
                // best-effort
            }
        }

        auditService.logSecurityEvent(
                "LEAVE_REQUEST_PROCESS",
                currentUserId,
                processedBy.getUsername(),
                SecurityUtils.getCurrentRoles(),
                "LEAVE_REQUEST_" + id,
                "SUCCESS",
                String.format("Status changed from '%s' to '%s'", oldStatus, newStatus)
        );

        return updated;
    }
}
