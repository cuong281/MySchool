package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.RewardDiscipline;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface RewardDisciplineRepository extends JpaRepository<RewardDiscipline, Integer> {

    @Override
    @EntityGraph(attributePaths = {"student", "student.schoolClass", "type", "schoolYear"})
    List<RewardDiscipline> findAll();

    @Override
    @EntityGraph(attributePaths = {"student", "student.schoolClass", "type", "schoolYear"})
    Optional<RewardDiscipline> findById(Integer id);

    @EntityGraph(attributePaths = {"student", "student.schoolClass", "type", "schoolYear"})
    List<RewardDiscipline> findByStudentIdOrderByIssuedDateDesc(Integer studentId);

    @EntityGraph(attributePaths = {"student", "student.schoolClass", "type", "schoolYear"})
    List<RewardDiscipline> findByStudentSchoolClassIdOrderByIssuedDateDesc(Integer classId);

    @EntityGraph(attributePaths = {"student", "student.schoolClass", "type", "schoolYear"})
    List<RewardDiscipline> findByStudentSchoolClassIdInOrderByIssuedDateDesc(Collection<Integer> classIds);

    @EntityGraph(attributePaths = {"student", "student.schoolClass", "type", "schoolYear"})
    List<RewardDiscipline> findAllByOrderByIssuedDateDesc();
}

