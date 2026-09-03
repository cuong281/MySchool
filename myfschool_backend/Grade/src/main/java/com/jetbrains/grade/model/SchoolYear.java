package com.jetbrains.grade.model;

import java.time.LocalDate;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "SchoolYears")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SchoolYear {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "SchoolYearID")
    private Integer id;

    @Column(name = "YearName", nullable = false, length = 20)
    private String name; // e.g., "2024-2025"

    @Column(name = "StartDate")
    private LocalDate startDate;

    @Column(name = "EndDate")
    private LocalDate endDate;

    @Column(name = "IsActive")
    private Boolean isActive = true;
}
