package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TeacherHomeroomDashboardDTO {
    private Integer classId;
    private String className;
    private String homeroomTeacherName;
    private long totalStudents;
    private long pendingLeaveRequests;
    private long totalLeaveRequests;
    private Double attendanceRate;
    private long totalAttendanceRecords;
    private long presentCount;
    private long excusedAbsenceCount;
    private long unexcusedAbsenceCount;
    private long lateCount;
    private Double averageClassGpa;
    private Map<String, Long> gradeDistribution;
}
