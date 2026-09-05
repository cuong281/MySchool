package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceSheetStudentDTO {
    private Integer studentId;
    private String studentName;
    private String studentCode;
    private String currentStatus; // PRESENT, EXCUSED_ABSENCE, UNEXCUSED_ABSENCE, LATE
    private Boolean hasApprovedLeave;
    private Integer leaveRequestId;
    private String leaveReason;
    private String note;
}
