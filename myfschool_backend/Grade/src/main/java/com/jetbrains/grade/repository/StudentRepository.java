package com.jetbrains.grade.repository;

import java.util.List;
import java.util.Optional;

import com.jetbrains.grade.model.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface StudentRepository extends JpaRepository<Student, Integer> {
    Optional<Student> findByUserId(Integer userId);
    Optional<Student> findByStudentCode(String studentCode);
    List<Student> findBySchoolClassId(Integer classId);
    long countBySchoolClassId(Integer classId);
}
