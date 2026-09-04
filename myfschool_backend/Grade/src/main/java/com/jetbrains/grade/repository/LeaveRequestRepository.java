package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.LeaveRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LeaveRequestRepository extends JpaRepository<LeaveRequest, Integer> {

    List<LeaveRequest> findByStudentIdOrderByCreatedAtDesc(Integer studentId);
    
    List<LeaveRequest> findByStatusOrderByCreatedAtDesc(String status);

    List<LeaveRequest> findByStudentSchoolClassHomeroomTeacherIdOrderByCreatedAtDesc(Integer teacherId);

    @Query("SELECT lr FROM LeaveRequest lr WHERE lr.student.schoolClass.id IN :classIds ORDER BY lr.createdAt DESC")
    List<LeaveRequest> findByClassIdsOrderByCreatedAtDesc(@Param("classIds") List<Integer> classIds);
}
