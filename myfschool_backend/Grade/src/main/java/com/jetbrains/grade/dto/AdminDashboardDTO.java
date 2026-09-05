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
public class AdminDashboardDTO {
    private String academicYear;
    private Integer semester;
    private long totalStudents;
    private long totalTeachers;
    private long totalClasses;
    private long totalGrades;
    private Double averageSchoolGpa;
    private Map<String, Long> gradeDistribution;

    // Attendance stats
    private long totalAttendanceRecords;
    private long presentCount;
    private long excusedAbsenceCount;
    private long unexcusedAbsenceCount;
    private long lateCount;
    private Double attendanceRate;

    // Leave request stats
    private long pendingLeaveRequests;
    private long approvedLeaveRequests;
    private long rejectedLeaveRequests;
    private long totalLeaveRequests;
}
