package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "Subjects")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Subject {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "SubjectID")
    private Integer id;

    @Column(name = "SubjectCode", nullable = false, length = 20, unique = true)
    private String subjectCode;

    @Column(name = "SubjectName", nullable = false, length = 100)
    private String subjectName;

    @Column(name = "IsActive")
    private Boolean isActive = true;
}
