package com.jetbrains.grade.dto;

import lombok.Data;

@Data
public class LeaveRequestStatusUpdateRequest {
    private String status;
    private Integer processedByUserId;
    private String adminNote;
}
