package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "SchoolClasses")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SchoolClass {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ClassID")
    private Integer id;

    @Column(name = "ClassName", nullable = false, length = 50)
    private String className;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "SchoolYearID")
    private SchoolYear schoolYear;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "HomeroomTeacherID")
    private Teacher homeroomTeacher;

    @Column(name = "Status", length = 20)
    private String status = "ACTIVE";
}
