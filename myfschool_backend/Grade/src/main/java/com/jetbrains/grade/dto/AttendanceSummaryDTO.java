package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceSummaryDTO {
    private Integer studentId;
    private String studentName;
    private String studentCode;
    private String className;

    private long totalSessions;
    private long presentCount;
    private long excusedAbsentCount;
    private long unexcusedAbsentCount;
    private long lateCount;

    private double attendanceRate; // percentage 0.0 - 100.0%
    private String statusNote;     // 'Chuyên cần tốt', 'Cảnh báo vắng học', 'Nguy cơ cấm thi'
}
