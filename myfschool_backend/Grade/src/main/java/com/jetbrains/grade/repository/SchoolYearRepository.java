package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.SchoolYear;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SchoolYearRepository extends JpaRepository<SchoolYear, Integer> {
}
