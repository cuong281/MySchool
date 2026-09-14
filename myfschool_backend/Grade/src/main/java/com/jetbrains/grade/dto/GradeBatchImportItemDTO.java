package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GradeBatchImportItemDTO {
    private Integer studentId;
    private String studentCode;
    private String studentName;
    private Integer subjectId;
    private String subjectCode;
    private Integer semester;
    private Double attendanceScore;
    private Double midtermScore;
    private Double finalScore;
    private Double score; // Used for IMPORT_MIDTERM or IMPORT_FINAL
    private Integer rowNumber;
}
