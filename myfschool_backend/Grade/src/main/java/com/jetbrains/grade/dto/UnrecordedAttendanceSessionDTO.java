package com.jetbrains.grade.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UnrecordedAttendanceSessionDTO {
    private Integer scheduleId;
    private Integer classId;
    private String className;
    private Integer subjectId;
    private String subjectName;
    private Integer teacherId;
    private String teacherName;
    private Integer slotNumber;

    @JsonFormat(pattern = "HH:mm")
    private LocalTime startTime;

    @JsonFormat(pattern = "HH:mm")
    private LocalTime endTime;

    private Long totalStudents;
    private Long recordedStudents;
    private Long delayMinutes;
    private String delayFormatted;

    // Attendance completion status: NOT_ATTENDED, PARTIALLY_ATTENDED
    private String attendanceStatus;

    // Time-based alert status: CHUA_TRE, CANH_BAO_TRE, QUA_HAN
    private String alertStatus;
    private String alertStatusLabel;

    private Boolean reminderSent;
}
