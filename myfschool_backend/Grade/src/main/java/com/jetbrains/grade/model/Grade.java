package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "Grades")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Grade {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "GradeID")
    private Integer id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "StudentID")
    private Student student;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "SubjectID")
    private Subject subject;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "SchoolYearID")
    private SchoolYear schoolYear;

    @Column(name = "Semester", nullable = false)
    private Integer semester;

    @Column(name = "AttendanceScore", nullable = false, columnDefinition = "DECIMAL(4,2) DEFAULT 0")
    private Double attendanceScore = 0.0;

    @Column(name = "MidtermScore", nullable = false, columnDefinition = "DECIMAL(4,2) DEFAULT 0")
    private Double midtermScore = 0.0;

    @Column(name = "FinalScore", nullable = false, columnDefinition = "DECIMAL(4,2) DEFAULT 0")
    private Double finalScore = 0.0;

    @Column(name = "AverageScore", insertable = false, updatable = false, columnDefinition = "DECIMAL(4,2)")
    private Double averageScore;

    @Column(name = "LetterGrade", insertable = false, updatable = false, length = 20)
    private String letterGrade;

    @Column(name = "GPA4", insertable = false, updatable = false, columnDefinition = "DECIMAL(3,1)")
    private Double gpa4;

    @Column(name = "CreatedAt")
    private LocalDateTime createdAt;

    @Column(name = "UpdatedAt")
    private LocalDateTime updatedAt;
}