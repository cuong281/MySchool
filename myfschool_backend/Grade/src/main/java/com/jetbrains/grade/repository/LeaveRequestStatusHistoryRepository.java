package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.LeaveRequestStatusHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LeaveRequestStatusHistoryRepository extends JpaRepository<LeaveRequestStatusHistory, Integer> {
}
