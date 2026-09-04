package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TeacherAssignmentDTO {
    private Integer id;
    private Integer teacherId;
    private String teacherName;
    private Integer classId;
    private String className;
    private Integer subjectId;
    private String subjectName;
    private String subjectCode;
    private String roleType; // HOMEROOM_TEACHER, SUBJECT_TEACHER
}
