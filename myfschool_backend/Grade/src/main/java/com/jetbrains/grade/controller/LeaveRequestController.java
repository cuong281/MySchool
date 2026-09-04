package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.LeaveRequestCreateRequest;
import com.jetbrains.grade.dto.LeaveRequestDTO;
import com.jetbrains.grade.model.FileEntity;
import com.jetbrains.grade.model.LeaveRequest;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.repository.FileRepository;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.security.SecurityUtils;
import com.jetbrains.grade.service.LeaveRequestService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/leave-requests")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class LeaveRequestController {

    private final LeaveRequestService leaveRequestService;
    private final StudentRepository studentRepository;
    private final FileRepository fileRepository;

    @PostMapping
    public ResponseEntity<?> create(@RequestBody LeaveRequestCreateRequest req) {
        try {
            if (req.getRequestType() == null || req.getFromDate() == null
                    || req.getToDate() == null || req.getReason() == null || req.getReason().isBlank()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Vui long nhap day du thong tin"));
            }

            if (req.getFromDate().isBefore(LocalDate.now())) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Ngay bat dau khong duoc truoc hom nay"));
            }

            if (req.getToDate().isBefore(req.getFromDate())) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "Ngay ket thuc khong duoc truoc ngay bat dau"));
            }

            // Always resolve student identity based on authenticated user or explicit admin target
            Integer targetUserId = req.getUserId() != null ? req.getUserId() : SecurityUtils.getCurrentUserId();
            Student student = studentRepository.findByUserId(targetUserId)
                    .orElseThrow(() -> new IllegalArgumentException("Student not found for that user ID"));

            LeaveRequest request = new LeaveRequest();
            request.setStudent(student);
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
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
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

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<List<LeaveRequestDTO>> getAll() {
        return ResponseEntity.ok(leaveRequestService.getAll().stream()
                .map(this::mapToDTO).toList());
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<?> updateStatus(@PathVariable Integer id, @RequestBody Map<String, Object> body) {
        String statusValue = (String) body.get("status");
        String adminNote = (String) body.get("adminNote");

        if (statusValue == null || statusValue.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Thieu status"));
        }

        LeaveRequest updated = leaveRequestService.updateStatus(id, statusValue, adminNote);
        return ResponseEntity.ok(Map.of(
                "message", "Cap nhat trang thai thanh cong",
                "status", updated.getStatus()
        ));
    }

    private LeaveRequestDTO mapToDTO(LeaveRequest l) {
        return LeaveRequestDTO.builder()
                .id(l.getId())
                .requestType(l.getRequestType())
                .fromDate(l.getFromDate())
                .toDate(l.getToDate())
                .reason(l.getReason())
                .status(l.getStatus())
                .adminNote(l.getAdminNote())
                .studentName(l.getStudent() != null ? l.getStudent().getFullName() : "")
                .studentCode(l.getStudent() != null ? l.getStudent().getStudentCode() : "")
                .build();
    }
}
