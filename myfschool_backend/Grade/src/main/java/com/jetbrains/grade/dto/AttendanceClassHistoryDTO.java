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
public class AttendanceClassHistoryDTO {
    private Integer classId;
    private String className;
    private Integer totalStudents;
    private Double attendanceRate;
    private Integer totalSessions;
    private Integer presentCount;
    private Integer excusedCount;
    private Integer unexcusedCount;
    private Integer lateCount;
    private List<AttendanceSessionSummaryDTO> sessions;
    private List<AttendanceAtRiskStudentDTO> atRiskStudents;
    private List<AttendanceStudentSummaryDTO> studentSummaries;
}
