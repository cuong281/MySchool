package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceAtRiskStudentDTO {
    private Integer studentId;
    private String studentName;
    private String studentCode;
    private Integer unexcusedCount;
    private Double rate;
    private String warningNote;
}
