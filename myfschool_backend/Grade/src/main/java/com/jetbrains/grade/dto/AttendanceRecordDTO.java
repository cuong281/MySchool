package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceRecordDTO {
    private Integer id;
    private Integer studentId;
    private String studentName;
    private String studentCode;
    private Integer classId;
    private String className;
    private Integer subjectId;
    private String subjectName;
    private LocalDate attendanceDate;
    private Integer slotNumber;
    private String status; // 'PRESENT', 'EXCUSED_ABSENCE', 'UNEXCUSED_ABSENCE', 'LATE'
    private String note;
    private String recordedByName;
}
