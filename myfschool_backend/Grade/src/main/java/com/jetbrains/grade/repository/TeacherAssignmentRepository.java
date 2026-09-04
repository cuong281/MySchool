package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.TeacherAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface TeacherAssignmentRepository extends JpaRepository<TeacherAssignment, Integer> {
    List<TeacherAssignment> findBySchoolClassId(Integer classId);
    List<TeacherAssignment> findByTeacherId(Integer teacherId);
    List<TeacherAssignment> findByTeacherIdAndRoleType(Integer teacherId, String roleType);
    List<TeacherAssignment> findByTeacherIdAndSchoolClassId(Integer teacherId, Integer classId);
    boolean existsByTeacherIdAndSchoolClassIdAndSubjectId(Integer teacherId, Integer classId, Integer subjectId);
    boolean existsByTeacherIdAndSchoolClassIdAndRoleType(Integer teacherId, Integer classId, String roleType);
    boolean existsByTeacherIdAndSchoolClassId(Integer teacherId, Integer classId);
}
