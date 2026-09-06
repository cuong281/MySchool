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

    List<Attendance> findBySchoolClassIdAndAttendanceDateAndSlotNumber(
            Integer classId, LocalDate date, Integer slotNumber);

    List<Attendance> findBySchoolClassIdAndAttendanceDateBetweenOrderByAttendanceDateDescSlotNumberDesc(
            Integer classId, LocalDate start, LocalDate end);

    List<Attendance> findBySchoolClassIdOrderByAttendanceDateDescSlotNumberDesc(Integer classId);

    @org.springframework.data.jpa.repository.Query("SELECT a.student.id AS studentId, a.status AS status, COUNT(a.id) AS count " +
           "FROM Attendance a WHERE a.schoolClass.id = :classId GROUP BY a.student.id, a.status")
    List<com.jetbrains.grade.dto.AttendanceStatusCountProjection> countAttendanceByClassGroupedByStudentAndStatus(
            @org.springframework.data.repository.query.Param("classId") Integer classId);
}
