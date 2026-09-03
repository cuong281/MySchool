package com.jetbrains.grade.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;

@Data
@Builder
public class GradeDTO {
    private Integer id;
    private Integer studentId;
    private String studentName;
    private String className;
    private String subjectCode;
    private String subjectName;
    private Double attendanceScore;
    private Double midtermScore;
    private Double finalScore;
    private Double averageScore;
    private String letterGrade;
    private Double gpa4;
    private Integer semester;
    private String academicYear;
    private String teacherName;
    private LocalDate lastModified;
}
