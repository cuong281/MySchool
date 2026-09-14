package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GradeBatchImportRequest {
    /**
     * "IMPORT_ALL" - Imports attendance, midterm, and final
     * "IMPORT_MIDTERM" - Only updates/sets midterm score
     * "IMPORT_FINAL" - Only updates/sets final score
     */
    private String importType;
    private Integer classId;
    private Integer subjectId;
    private String subjectCode;
    private Integer schoolYearId;
    private Integer semester; // 1 or 2
    private List<GradeBatchImportItemDTO> items;
}
