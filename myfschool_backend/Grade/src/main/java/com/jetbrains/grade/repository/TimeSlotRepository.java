package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.TimeSlot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TimeSlotRepository extends JpaRepository<TimeSlot, Integer> {
    List<TimeSlot> findByIsActiveTrueOrderBySlotNumberAsc();
    Optional<TimeSlot> findBySlotNumberAndIsActiveTrue(Integer slotNumber);
    Optional<TimeSlot> findBySlotNumber(Integer slotNumber);
}

