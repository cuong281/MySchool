package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.TeacherAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface TeacherAssignmentRepository extends JpaRepository<TeacherAssignment, Integer> {
    List<TeacherAssignment> findBySchoolClassId(Integer classId);
}
