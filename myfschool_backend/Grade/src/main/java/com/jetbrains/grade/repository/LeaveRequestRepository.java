package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.LeaveRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LeaveRequestRepository extends JpaRepository<LeaveRequest, Integer> {

    List<LeaveRequest> findByStudentIdOrderByCreatedAtDesc(Integer studentId);
    
    List<LeaveRequest> findByStatusOrderByCreatedAtDesc(String status);
}
