package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "TeacherAssignments")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TeacherAssignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "AssignmentID")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "TeacherID", nullable = false)
    private Teacher teacher;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "SubjectID")
    private Subject subject; // Nullable for HOMEROOM_TEACHER

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ClassID", nullable = false)
    private SchoolClass schoolClass;

    @Column(name = "RoleType", nullable = false, length = 50)
    private String roleType; // SUBJECT_TEACHER, HOMEROOM_TEACHER
}
