package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(
    name = "ClassSchedules",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"ClassID", "DayOfWeek", "TimeSlotID"})
    }
)
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClassSchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ScheduleID")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ClassID", nullable = false)
    private SchoolClass schoolClass;

    @Enumerated(EnumType.STRING)
    @Column(name = "DayOfWeek", nullable = false, length = 20)
    private DayOfWeekVN dayOfWeek;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "TimeSlotID", nullable = false)
    private TimeSlot timeSlot;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "SubjectID", nullable = false)
    private Subject subject;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "TeacherID", nullable = false)
    private Teacher teacher;

    @Column(name = "RoomName", length = 50)
    private String roomName;

    @Column(name = "Status", length = 20)
    private String status = "ACTIVE"; // ACTIVE, CANCELLED
}
