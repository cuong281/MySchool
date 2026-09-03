package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.Grade;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GradeRepository extends JpaRepository<Grade, Integer> {
    List<Grade> findByStudentId(Integer studentId);
    List<Grade> findByStudentSchoolClassId(Integer classId);
    List<Grade> findByStudentIdAndSemester(Integer studentId, Integer semester);
    boolean existsByStudentIdAndSubjectIdAndSchoolYearIdAndSemester(
            Integer studentId, Integer subjectId, Integer schoolYearId, Integer semester);
}