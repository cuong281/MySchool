package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.RewardDisciplineType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RewardDisciplineTypeRepository extends JpaRepository<RewardDisciplineType, Integer> {
}
