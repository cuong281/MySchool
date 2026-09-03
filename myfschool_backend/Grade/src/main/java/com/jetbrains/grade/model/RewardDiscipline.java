package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "RewardDisciplines")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RewardDiscipline {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "RecordID")
    private Integer id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "StudentID", nullable = false)
    private Student student;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "TypeID", nullable = false)
    private RewardDisciplineType type;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "SchoolYearID", nullable = false)
    private SchoolYear schoolYear;

    @Column(name = "Semester")
    private Integer semester;

    @Column(name = "DecisionNumber", length = 50)
    private String decisionNumber;
    
    @Column(name = "Content", length = 1000)
    private String content;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "IssuedByUserID")
    private User issuedBy;

    @Column(name = "IssuedDate", nullable = false)
    private LocalDate issuedDate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "FileID")
    private FileEntity file;

    @Column(name = "CreatedAt", updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
    
    @Column(name = "UpdatedAt")
    private LocalDateTime updatedAt = LocalDateTime.now();
}
