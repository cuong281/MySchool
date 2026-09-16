package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.LeaveRequestCreateRequest;
import com.jetbrains.grade.dto.LeaveRequestDTO;
import com.jetbrains.grade.model.FileEntity;
import com.jetbrains.grade.model.LeaveRequest;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.model.Teacher;
import com.jetbrains.grade.repository.FileRepository;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.repository.TeacherRepository;
import com.jetbrains.grade.security.SecurityUtils;
import com.jetbrains.grade.service.LeaveRequestService;
import lombok.RequiredArgsConstructor;
import com.jetbrains.grade.dto.PageResponse;
import com.jetbrains.grade.util.PaginationUtils;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/leave-requests")
@RequiredArgsConstructor
@Tag(name = "Leave Requests", description = "Quản lý đơn xin nghỉ học của học sinh và nghỉ dạy của giáo viên")
public class LeaveRequestController {

    private final LeaveRequestService leaveRequestService;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final FileRepository fileRepository;

    @PostMapping
    public ResponseEntity<?> create(@jakarta.validation.Valid @RequestBody LeaveRequestCreateRequest req) {
        if (req.getRequestType() == null || req.getFromDate() == null
                || req.getToDate() == null || req.getReason() == null || req.getReason().isBlank()) {
            throw new IllegalArgumentException("Vui long nhap day du thong tin");
        }

        if (req.getFromDate().isBefore(LocalDate.now())) {
            throw new IllegalArgumentException("Ngay bat dau khong duoc truoc hom nay");
        }

        if (req.getToDate().isBefore(req.getFromDate())) {
            throw new IllegalArgumentException("Ngay ket thuc khong duoc truoc ngay bat dau");
        }

        // Resolve student or teacher identity based on target/authenticated user
        Integer targetUserId = req.getUserId() != null ? req.getUserId() : SecurityUtils.getCurrentUserId();
        var studentOpt = studentRepository.findByUserId(targetUserId);
        var teacherOpt = teacherRepository.findByUserId(targetUserId);

        LeaveRequest request = new LeaveRequest();
        if (studentOpt.isPresent()) {
            request.setStudent(studentOpt.get());
        } else if (teacherOpt.isPresent()) {
            request.setTeacher(teacherOpt.get());
        } else {
            throw new IllegalArgumentException("Khong tim thay thong tin hoc sinh hoac giao vien cho tai khoan nay");
        }
        request.setRequestType(req.getRequestType());
        request.setFromDate(req.getFromDate());
        request.setToDate(req.getToDate());
        request.setReason(req.getReason());

        if (req.getFileId() != null) {
            FileEntity file = fileRepository.findById(req.getFileId())
                    .orElseThrow(() -> new IllegalArgumentException("Attachment file not found"));
            request.setAttachmentFile(file);
        }

        LeaveRequest saved = leaveRequestService.create(request);

        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "requestId", saved.getId(),
                "message", "Tao don thanh cong"
        ));
    }

    @GetMapping("/me")
    public ResponseEntity<List<LeaveRequestDTO>> getMyRequests() {
        return ResponseEntity.ok(leaveRequestService.getMyLeaveRequests().stream()
                .map(this::mapToDTO).toList());
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<LeaveRequestDTO>> getByUser(@PathVariable Integer userId) {
        return ResponseEntity.ok(leaveRequestService.getByUserId(userId).stream()
                .map(this::mapToDTO).toList());
    }

    @Operation(summary = "Lấy danh sách đơn xin nghỉ phép", description = "Admin xem toàn trường; Giáo viên xem các lớp chủ nhiệm. Nếu truyền 'page', kết quả được phân trang (PageResponse); nếu không truyền, trả về List thông thường.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Lấy danh sách thành công"),
            @ApiResponse(responseCode = "401", description = "Chưa xác thực"),
            @ApiResponse(responseCode = "403", description = "Học sinh không có quyền xem toàn trường")
    })
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<?> getAll(
            @Parameter(description = "Số trang (0-indexed). Nếu không truyền sẽ trả về toàn bộ danh sách.")
            @RequestParam(required = false) Integer page,
            @Parameter(description = "Kích thước trang (mặc định 20, tối đa 100).")
            @RequestParam(required = false) Integer size,
            @Parameter(description = "Trường sắp xếp.")
            @RequestParam(required = false) String sort,
            @Parameter(description = "Hướng sắp xếp (asc hoặc desc).")
            @RequestParam(required = false, defaultValue = "desc") String direction
    ) {
        List<LeaveRequestDTO> allRequests = leaveRequestService.getAll().stream()
                .map(this::mapToDTO)
                .toList();

        if (page == null) {
            return ResponseEntity.ok(allRequests);
        }

        Pageable pageable = PaginationUtils.createPageable(page, size, sort, direction);
        int start = (int) Math.min(pageable.getOffset(), allRequests.size());
        int end = Math.min(start + pageable.getPageSize(), allRequests.size());
        List<LeaveRequestDTO> pagedContent = allRequests.subList(start, end);
        Page<LeaveRequestDTO> pageResult = new PageImpl<>(pagedContent, pageable, allRequests.size());

        return ResponseEntity.ok(PageResponse.fromPage(pageResult));
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<?> updateStatus(@PathVariable Integer id, @RequestBody Map<String, Object> body) {
        String statusValue = (String) body.get("status");
        String adminNote = (String) body.get("adminNote");

        if (statusValue == null || statusValue.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Thieu status"));
        }

        if ("APPROVED".equalsIgnoreCase(statusValue)) {
            statusValue = "Đã duyệt";
        } else if ("REJECTED".equalsIgnoreCase(statusValue)) {
            statusValue = "Từ chối";
        } else if ("PENDING".equalsIgnoreCase(statusValue)) {
            statusValue = "Chờ duyệt";
        }

        LeaveRequest updated = leaveRequestService.updateStatus(id, statusValue, adminNote);
        return ResponseEntity.ok(Map.of(
                "message", "Cap nhat trang thai thanh cong",
                "status", updated.getStatus()
        ));
    }

    private LeaveRequestDTO mapToDTO(LeaveRequest l) {
        String className = (l.getStudent() != null && l.getStudent().getSchoolClass() != null)
                ? l.getStudent().getSchoolClass().getClassName()
                : "";
        String name = l.getStudent() != null ? l.getStudent().getFullName()
                : (l.getTeacher() != null ? l.getTeacher().getFullName() : "");
        String code = l.getStudent() != null ? l.getStudent().getStudentCode() : "";
        String role = l.getTeacher() != null ? "TEACHER" : "STUDENT";
        Integer teacherId = l.getTeacher() != null ? l.getTeacher().getId() : null;
        String teacherName = l.getTeacher() != null ? l.getTeacher().getFullName() : null;

        return LeaveRequestDTO.builder()
                .id(l.getId())
                .requestType(l.getRequestType())
                .fromDate(l.getFromDate())
                .toDate(l.getToDate())
                .reason(l.getReason())
                .status(l.getStatus())
                .adminNote(l.getAdminNote())
                .studentName(name)
                .studentCode(code)
                .className(className)
                .teacherId(teacherId)
                .teacherName(teacherName)
                .role(role)
                .build();
    }
}
