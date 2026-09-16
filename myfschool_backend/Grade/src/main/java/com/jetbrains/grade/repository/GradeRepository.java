package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.Grade;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GradeRepository extends JpaRepository<Grade, Integer> {

    @Override
    @EntityGraph(attributePaths = {"student", "student.schoolClass", "subject", "schoolYear"})
    List<Grade> findAll();

    @Override
    @EntityGraph(attributePaths = {"student", "student.schoolClass", "subject", "schoolYear"})
    org.springframework.data.domain.Page<Grade> findAll(org.springframework.data.domain.Pageable pageable);

    @Override
    @EntityGraph(attributePaths = {"student", "student.schoolClass", "subject", "schoolYear"})
    Optional<Grade> findById(Integer id);

    @EntityGraph(attributePaths = {"student", "student.schoolClass", "subject", "schoolYear"})
    List<Grade> findByStudentId(Integer studentId);

    @EntityGraph(attributePaths = {"student", "student.schoolClass", "subject", "schoolYear"})
    List<Grade> findByStudentSchoolClassId(Integer classId);

    @EntityGraph(attributePaths = {"student", "student.schoolClass", "subject", "schoolYear"})
    List<Grade> findByStudentSchoolClassIdAndSubjectId(Integer classId, Integer subjectId);

    @EntityGraph(attributePaths = {"student", "student.schoolClass", "subject", "schoolYear"})
    List<Grade> findByStudentIdAndSemester(Integer studentId, Integer semester);

    boolean existsByStudentIdAndSubjectIdAndSchoolYearIdAndSemester(
            Integer studentId, Integer subjectId, Integer schoolYearId, Integer semester);

    @EntityGraph(attributePaths = {"student", "student.schoolClass", "subject", "schoolYear"})
    Optional<Grade> findByStudentIdAndSubjectIdAndSchoolYearIdAndSemester(
            Integer studentId, Integer subjectId, Integer schoolYearId, Integer semester);

    @EntityGraph(attributePaths = {"student", "student.schoolClass", "subject", "schoolYear"})
    @Query("SELECT g FROM Grade g WHERE " +
           "(g.student.schoolClass.homeroomTeacher.id = :teacherId) OR " +
           "EXISTS (SELECT ta FROM TeacherAssignment ta WHERE ta.teacher.id = :teacherId " +
           "AND ta.schoolClass.id = g.student.schoolClass.id AND ta.subject.id = g.subject.id)")
    List<Grade> findByTeacherScope(@Param("teacherId") Integer teacherId);

    @EntityGraph(attributePaths = {"student", "student.schoolClass", "subject", "schoolYear"})
    @Query("SELECT g FROM Grade g WHERE " +
           "(g.student.schoolClass.homeroomTeacher.id = :teacherId) OR " +
           "EXISTS (SELECT ta FROM TeacherAssignment ta WHERE ta.teacher.id = :teacherId " +
           "AND ta.schoolClass.id = g.student.schoolClass.id AND ta.subject.id = g.subject.id)")
    org.springframework.data.domain.Page<Grade> findByTeacherScope(@Param("teacherId") Integer teacherId, org.springframework.data.domain.Pageable pageable);

    @EntityGraph(attributePaths = {"student", "student.schoolClass", "subject", "schoolYear"})
    @Query("SELECT g FROM Grade g WHERE g.student.schoolClass.id = :classId AND " +
           "EXISTS (SELECT ta FROM TeacherAssignment ta WHERE ta.teacher.id = :teacherId " +
           "AND ta.schoolClass.id = :classId AND ta.subject.id = g.subject.id)")
    List<Grade> findByClassIdAndTeacherSubjectScope(@Param("classId") Integer classId, @Param("teacherId") Integer teacherId);
}