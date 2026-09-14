package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.Subject;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SubjectRepository extends JpaRepository<Subject, Integer> {
    Optional<Subject> findBySubjectCode(String subjectCode);
    Optional<Subject> findBySubjectCodeIgnoreCase(String subjectCode);
}
