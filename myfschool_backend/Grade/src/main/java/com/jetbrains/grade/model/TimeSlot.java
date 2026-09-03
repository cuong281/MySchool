package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalTime;

@Entity
@Table(name = "TimeSlots")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TimeSlot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "TimeSlotID")
    private Integer id;

    @Column(name = "SlotNumber", nullable = false)
    private Integer slotNumber; // e.g., 1, 2, 3

    @Column(name = "StartTime", nullable = false)
    private LocalTime startTime;

    @Column(name = "EndTime", nullable = false)
    private LocalTime endTime;

    @Enumerated(EnumType.STRING)
    @Column(name = "SessionType", nullable = false, length = 20)
    private SessionType sessionType;

    @Column(name = "IsActive", nullable = false)
    private Boolean isActive = true;
}
