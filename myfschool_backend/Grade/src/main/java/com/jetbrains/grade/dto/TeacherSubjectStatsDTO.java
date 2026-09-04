package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TeacherSubjectStatsDTO {
    private Integer classId;
    private String className;
    private Integer subjectId;
    private String subjectName;
    private long totalStudents;
    private long gradedCount;
    private Double highestScore;
    private Double lowestScore;
    private Double averageScore;
    private long passCount;
    private long failCount;
    private Double passRate;
}
