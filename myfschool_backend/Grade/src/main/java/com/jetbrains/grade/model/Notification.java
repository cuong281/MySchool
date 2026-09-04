package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "Notifications")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "NotificationID")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "UserID", nullable = false)
    private User user;

    @Column(name = "Title", nullable = false, length = 200)
    private String title;

    @Column(name = "Body", nullable = false, length = 1000)
    private String body;

    @Column(name = "Type", nullable = false, length = 50)
    private String type; // 'GRADE_UPDATE', 'LEAVE_REQUEST_STATUS', 'ATTENDANCE_ALERT', 'ANNOUNCEMENT', 'SYSTEM'

    @Column(name = "ReferenceID")
    private Integer referenceId;

    @Column(name = "IsRead", nullable = false)
    private Boolean isRead = false;

    @Column(name = "CreatedAt")
    private LocalDateTime createdAt;

    @Column(name = "ReadAt")
    private LocalDateTime readAt;
}
