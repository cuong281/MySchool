package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.SchoolClass;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SchoolClassRepository extends JpaRepository<SchoolClass, Integer> {
    List<SchoolClass> findByHomeroomTeacherId(Integer teacherId);
    boolean existsByIdAndHomeroomTeacherId(Integer classId, Integer teacherId);
}
