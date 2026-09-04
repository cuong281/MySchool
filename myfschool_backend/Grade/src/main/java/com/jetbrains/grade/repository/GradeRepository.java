package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.Grade;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

@Repository
public interface GradeRepository extends JpaRepository<Grade, Integer> {
    List<Grade> findByStudentId(Integer studentId);
    List<Grade> findByStudentSchoolClassId(Integer classId);
    List<Grade> findByStudentSchoolClassIdAndSubjectId(Integer classId, Integer subjectId);
    List<Grade> findByStudentIdAndSemester(Integer studentId, Integer semester);
    boolean existsByStudentIdAndSubjectIdAndSchoolYearIdAndSemester(
            Integer studentId, Integer subjectId, Integer schoolYearId, Integer semester);

    @Query("SELECT g FROM Grade g WHERE " +
           "(g.student.schoolClass.homeroomTeacher.id = :teacherId) OR " +
           "EXISTS (SELECT ta FROM TeacherAssignment ta WHERE ta.teacher.id = :teacherId " +
           "AND ta.schoolClass.id = g.student.schoolClass.id AND ta.subject.id = g.subject.id)")
    List<Grade> findByTeacherScope(@Param("teacherId") Integer teacherId);

    @Query("SELECT g FROM Grade g WHERE g.student.schoolClass.id = :classId AND " +
           "EXISTS (SELECT ta FROM TeacherAssignment ta WHERE ta.teacher.id = :teacherId " +
           "AND ta.schoolClass.id = :classId AND ta.subject.id = g.subject.id)")
    List<Grade> findByClassIdAndTeacherSubjectScope(@Param("classId") Integer classId, @Param("teacherId") Integer teacherId);
}