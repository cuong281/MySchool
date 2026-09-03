package com.jetbrains.grade.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;

@Data
@Builder
public class LeaveRequestDTO {
    private Integer id;
    private String requestType;
    private LocalDate fromDate;
    private LocalDate toDate;
    private String reason;
    private String status;
    private String adminNote;
    private String studentName;
    private String studentCode;
}
