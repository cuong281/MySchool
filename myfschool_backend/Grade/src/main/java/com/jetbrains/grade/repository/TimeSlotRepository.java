package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.TimeSlot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TimeSlotRepository extends JpaRepository<TimeSlot, Integer> {
    List<TimeSlot> findByIsActiveTrueOrderBySlotNumberAsc();
}
