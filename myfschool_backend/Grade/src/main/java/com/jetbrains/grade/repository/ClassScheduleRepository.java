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
}
