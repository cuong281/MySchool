package com.jetbrains.grade.dto;

import lombok.Data;
import java.time.LocalDate;

@Data
public class LeaveRequestCreateRequest {
    private Integer userId;
    private String requestType;
    private LocalDate fromDate;
    private LocalDate toDate;
    private String reason;
    private Integer fileId;
}
