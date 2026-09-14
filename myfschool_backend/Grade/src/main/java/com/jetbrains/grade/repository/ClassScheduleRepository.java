package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.ClassSchedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ClassScheduleRepository extends JpaRepository<ClassSchedule, Integer> {

    @Query("""
        SELECT cs FROM ClassSchedule cs
        JOIN FETCH cs.schoolClass
        JOIN FETCH cs.subject
        JOIN FETCH cs.teacher
        JOIN FETCH cs.timeSlot
        WHERE cs.schoolClass.id = :classId
        ORDER BY cs.dayOfWeek ASC, cs.timeSlot.slotNumber ASC
    """)
    List<ClassSchedule> findBySchoolClassIdWithDetails(@Param("classId") Integer classId);

    @Query("""
        SELECT cs FROM ClassSchedule cs
        JOIN FETCH cs.schoolClass
        JOIN FETCH cs.subject
        JOIN FETCH cs.teacher
        JOIN FETCH cs.timeSlot
        WHERE cs.teacher.id = :teacherId
        ORDER BY cs.dayOfWeek ASC, cs.timeSlot.slotNumber ASC
    """)
    List<ClassSchedule> findByTeacherIdWithDetails(@Param("teacherId") Integer teacherId);

    @Query("""
        SELECT cs FROM ClassSchedule cs
        WHERE cs.schoolClass.id = :classId
          AND cs.dayOfWeek = :dayOfWeek
          AND cs.timeSlot.slotNumber = :slotNumber
          AND cs.status = 'ACTIVE'
    """)
    java.util.Optional<ClassSchedule> findActiveClassSchedule(
            @Param("classId") Integer classId,
            @Param("dayOfWeek") com.jetbrains.grade.model.DayOfWeekVN dayOfWeek,
            @Param("slotNumber") Integer slotNumber
    );

    @Query("""
        SELECT cs FROM ClassSchedule cs
        JOIN FETCH cs.schoolClass
        JOIN FETCH cs.subject
        JOIN FETCH cs.teacher t
        LEFT JOIN FETCH t.user
        JOIN FETCH cs.timeSlot
        WHERE cs.dayOfWeek = :dayOfWeek
          AND cs.status = 'ACTIVE'
        ORDER BY cs.timeSlot.startTime ASC, cs.schoolClass.className ASC
    """)
    List<ClassSchedule> findActiveSchedulesByDayOfWeekWithDetails(
            @Param("dayOfWeek") com.jetbrains.grade.model.DayOfWeekVN dayOfWeek
    );
}
