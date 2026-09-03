package com.jetbrains.grade.service;

import com.jetbrains.grade.model.LeaveRequest;
import com.jetbrains.grade.model.LeaveRequestStatusHistory;

import com.jetbrains.grade.model.User;
import com.jetbrains.grade.repository.LeaveRequestRepository;
import com.jetbrains.grade.repository.LeaveRequestStatusHistoryRepository;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class LeaveRequestService {

    private final LeaveRequestRepository leaveRequestRepository;
    private final StudentRepository studentRepository;
    private final UserRepository userRepository;
    private final LeaveRequestStatusHistoryRepository historyRepository;

    @Transactional
    public LeaveRequest create(LeaveRequest request) {
        request.setId(null);
        request.setStatus("Chờ duyệt");
        request.setCreatedAt(LocalDateTime.now());
        request.setUpdatedAt(LocalDateTime.now());
        return leaveRequestRepository.save(request);
    }

    public List<LeaveRequest> getByUserId(Integer userId) {
        var studentOpt = studentRepository.findByUserId(userId);
        if (studentOpt.isEmpty()) return List.of();
        return leaveRequestRepository.findByStudentIdOrderByCreatedAtDesc(studentOpt.get().getId());
    }

    public List<LeaveRequest> getAll() {
        return leaveRequestRepository.findAll();
    }

    @Transactional
    public LeaveRequest updateStatus(Integer id, String newStatus, Integer processedByUserId, String adminNote) {
        LeaveRequest request = leaveRequestRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Khong tim thay don voi ID: " + id));

        User processedBy = userRepository.findByIdAndIsActiveTrue(processedByUserId)
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

        return updated;
    }
}
