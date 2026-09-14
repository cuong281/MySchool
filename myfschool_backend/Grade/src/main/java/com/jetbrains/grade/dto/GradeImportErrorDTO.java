package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GradeImportErrorDTO {
    private Integer rowNumber;
    private Integer studentId;
    private String studentCode;
    private String studentName;
    private String field;
    private String message;
}
