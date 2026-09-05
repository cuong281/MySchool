package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceBatchItemDTO {
    private Integer studentId;
    private String status; // 'PRESENT', 'EXCUSED_ABSENCE', 'UNEXCUSED_ABSENCE', 'LATE'
    private String note;
    private Boolean overrideLeave;
    private String overrideReason;
}
