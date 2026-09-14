package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.SchoolYear;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SchoolYearRepository extends JpaRepository<SchoolYear, Integer> {
    Optional<SchoolYear> findByIsActiveTrue();
    Optional<SchoolYear> findByName(String name);
}
