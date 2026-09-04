package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.Attendance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface AttendanceRepository extends JpaRepository<Attendance, Integer> {

    List<Attendance> findByStudentIdOrderByAttendanceDateDesc(Integer studentId);

    List<Attendance> findByStudentIdAndAttendanceDateBetweenOrderByAttendanceDateAsc(
            Integer studentId, LocalDate start, LocalDate end);

    List<Attendance> findBySchoolClassIdAndAttendanceDateOrderBySlotNumberAsc(
            Integer classId, LocalDate date);

    Optional<Attendance> findByStudentIdAndAttendanceDateAndSlotNumber(
            Integer studentId, LocalDate date, Integer slotNumber);

    long countByStudentIdAndStatus(Integer studentId, String status);

    long countByStudentId(Integer studentId);

    List<Attendance> findBySchoolClassId(Integer classId);
}
