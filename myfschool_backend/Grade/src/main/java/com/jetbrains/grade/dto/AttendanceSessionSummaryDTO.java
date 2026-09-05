package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceSessionSummaryDTO {
    private LocalDate attendanceDate;
    private Integer slotNumber;
    private Integer subjectId;
    private String subjectName;
    private Integer presentCount;
    private Integer excusedCount;
    private Integer unexcusedCount;
    private Integer lateCount;
    private Integer totalCount;
    private Boolean canEdit;
    private List<String> absentStudents;
}
