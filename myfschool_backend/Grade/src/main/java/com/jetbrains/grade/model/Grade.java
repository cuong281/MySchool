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

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "StudentID")
    private Student student;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "SubjectID")
    private Subject subject;

    @ManyToOne(fetch = FetchType.LAZY)
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

    @Column(name = "AverageScore", columnDefinition = "DECIMAL(4,2)")
    private Double averageScore;

    @Column(name = "LetterGrade", length = 20)
    private String letterGrade;

    @Column(name = "GPA4", columnDefinition = "DECIMAL(3,1)")
    private Double gpa4;

    @Column(name = "CreatedAt")
    private LocalDateTime createdAt;

    @Column(name = "UpdatedAt")
    private LocalDateTime updatedAt;

    @PrePersist
    @PreUpdate
    public void calculateComputedFields() {
        if (attendanceScore != null && midtermScore != null && finalScore != null) {
            double avg = Math.round(((attendanceScore + midtermScore * 2.0 + finalScore * 3.0) / 6.0) * 10.0) / 10.0;
            this.averageScore = avg;
            if (avg >= 9.0) {
                this.letterGrade = "A+";
                this.gpa4 = 4.0;
            } else if (avg >= 8.5) {
                this.letterGrade = "A";
                this.gpa4 = 3.8;
            } else if (avg >= 8.0) {
                this.letterGrade = "B+";
                this.gpa4 = 3.5;
            } else if (avg >= 7.0) {
                this.letterGrade = "B";
                this.gpa4 = 3.0;
            } else if (avg >= 6.5) {
                this.letterGrade = "C+";
                this.gpa4 = 2.5;
            } else if (avg >= 5.5) {
                this.letterGrade = "C";
                this.gpa4 = 2.0;
            } else if (avg >= 5.0) {
                this.letterGrade = "D+";
                this.gpa4 = 1.5;
            } else if (avg >= 4.0) {
                this.letterGrade = "D";
                this.gpa4 = 1.0;
            } else {
                this.letterGrade = "F";
                this.gpa4 = 0.0;
            }
        }
    }
}