package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceStudentSummaryDTO {
    private Integer studentId;
    private String studentName;
    private String studentCode;
    private Integer presentCount;
    private Integer excusedCount;
    private Integer unexcusedCount;
    private Integer lateCount;
    private Integer totalTrackedSessions;
    private Double attendanceRate;
    private Boolean isAtRisk;
    private String warningNote;
    private List<AttendanceRecordDTO> records;
}
