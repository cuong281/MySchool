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
public class AttendanceBatchRequest {
    private Integer classId;
    private Integer subjectId;
    private Integer slotNumber;
    private LocalDate attendanceDate;
    private List<AttendanceBatchItemDTO> items;
}
