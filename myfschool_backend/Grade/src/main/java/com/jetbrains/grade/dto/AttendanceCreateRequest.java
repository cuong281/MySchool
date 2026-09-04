package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceCreateRequest {
    private Integer studentId;
    private Integer classId;
    private Integer subjectId;
    private LocalDate attendanceDate;
    private Integer slotNumber;
    private String status; // 'PRESENT', 'EXCUSED_ABSENCE', 'UNEXCUSED_ABSENCE', 'LATE'
    private String note;
}
