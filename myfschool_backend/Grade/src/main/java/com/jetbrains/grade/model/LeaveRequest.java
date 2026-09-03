package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "LeaveRequests")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LeaveRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "RequestID")
    private Integer id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "StudentID", nullable = false)
    private Student student;

    @Column(name = "RequestType", nullable = false, length = 50)
    private String requestType;

    @Column(name = "FromDate", nullable = false)
    private LocalDate fromDate;

    @Column(name = "ToDate", nullable = false)
    private LocalDate toDate;

    @Column(name = "Reason", nullable = false, length = 1000)
    private String reason;

    @Column(name = "Status", nullable = false, length = 20)
    private String status = "Chờ duyệt";

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "AttachmentFileID")
    private FileEntity attachmentFile;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ProcessedByUserID")
    private User processedBy;

    @Column(name = "ProcessedAt")
    private LocalDateTime processedAt;

    @Column(name = "AdminNote", length = 1000)
    private String adminNote;

    @Column(name = "CreatedAt", updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
    
    @Column(name = "UpdatedAt")
    private LocalDateTime updatedAt = LocalDateTime.now();
}
