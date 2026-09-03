package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "LeaveRequestStatusHistory")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LeaveRequestStatusHistory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "HistoryID")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "RequestID", nullable = false)
    private LeaveRequest leaveRequest;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ChangedByUserID", nullable = false)
    private User changedBy;

    @Column(name = "OldStatus", length = 50)
    private String oldStatus;

    @Column(name = "NewStatus", nullable = false, length = 50)
    private String newStatus;

    @Column(name = "Note", length = 1000)
    private String note;

    @Column(name = "ChangedAt")
    private LocalDateTime changedAt = LocalDateTime.now();
}
