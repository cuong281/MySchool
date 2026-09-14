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
    
    List<LeaveRequest> findByTeacherIdOrderByCreatedAtDesc(Integer teacherId);
    
    List<LeaveRequest> findByStatusOrderByCreatedAtDesc(String status);

    List<LeaveRequest> findByStudentSchoolClassHomeroomTeacherIdOrderByCreatedAtDesc(Integer teacherId);

    @Query("SELECT lr FROM LeaveRequest lr WHERE lr.student.schoolClass.id IN :classIds ORDER BY lr.createdAt DESC")
    List<LeaveRequest> findByClassIdsOrderByCreatedAtDesc(@Param("classIds") List<Integer> classIds);

    @Query("SELECT lr FROM LeaveRequest lr WHERE lr.student.id IN :studentIds " +
           "AND (UPPER(lr.status) = 'APPROVED' OR UPPER(lr.status) LIKE '%DUY%T%') " +
           "AND lr.fromDate <= :attendanceDate AND lr.toDate >= :attendanceDate")
    List<LeaveRequest> findApprovedLeavesByStudentIdsAndDate(@Param("studentIds") List<Integer> studentIds, @Param("attendanceDate") java.time.LocalDate attendanceDate);

    @Query("SELECT lr FROM LeaveRequest lr WHERE lr.student.id = :studentId " +
           "AND (UPPER(lr.status) = 'APPROVED' OR UPPER(lr.status) LIKE '%DUY%T%') " +
           "AND lr.fromDate <= :attendanceDate AND lr.toDate >= :attendanceDate")
    java.util.Optional<LeaveRequest> findApprovedLeaveByStudentAndDate(@Param("studentId") Integer studentId, @Param("attendanceDate") java.time.LocalDate attendanceDate);
}

