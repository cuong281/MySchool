package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.RewardDiscipline;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface RewardDisciplineRepository extends JpaRepository<RewardDiscipline, Integer> {
    List<RewardDiscipline> findByStudentIdOrderByIssuedDateDesc(Integer studentId);
    List<RewardDiscipline> findByStudentSchoolClassIdOrderByIssuedDateDesc(Integer classId);
    List<RewardDiscipline> findByStudentSchoolClassIdInOrderByIssuedDateDesc(Collection<Integer> classIds);
    List<RewardDiscipline> findAllByOrderByIssuedDateDesc();
}

