package com.jetbrains.grade.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceSheetDTO {
    private Integer classId;
    private String className;
    private Integer subjectId;
    private String subjectName;
    private Integer slotNumber;

    @JsonFormat(pattern = "HH:mm")
    private LocalTime startTime;

    @JsonFormat(pattern = "HH:mm")
    private LocalTime endTime;

    private LocalDate attendanceDate;
    private Boolean canEdit;
    private String lockReason; // null, "NOT_STARTED", "EXPIRED_PAST_DAY"
    private Integer totalStudents;
    private List<AttendanceSheetStudentDTO> students;
}
