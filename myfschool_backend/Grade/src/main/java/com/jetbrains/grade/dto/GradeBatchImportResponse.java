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
public class GradeBatchImportResponse {
    private boolean success;
    private int totalProcessed;
    private int createdCount;
    private int updatedCount;
    private int failedCount;
    private List<GradeImportErrorDTO> errors;
}
