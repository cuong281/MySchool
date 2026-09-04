package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationDTO {
    private Integer id;
    private Integer userId;
    private String title;
    private String body;
    private String type; // 'GRADE_UPDATE', 'LEAVE_REQUEST_STATUS', 'ATTENDANCE_ALERT', 'ANNOUNCEMENT', 'SYSTEM'
    private Integer referenceId;
    private Boolean isRead;
    private LocalDateTime createdAt;
    private LocalDateTime readAt;
}
