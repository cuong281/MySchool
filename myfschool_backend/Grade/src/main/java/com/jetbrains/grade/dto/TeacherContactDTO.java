package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TeacherContactDTO {
    private Integer teacherId;
    private Integer userId;
    private String fullName;
    private String email;
    private String phone;
    private String avatarUrl;
    private String subjectName; // Can be null for homeroom teachers
    private String roleType;    // SUBJECT_TEACHER, HOMEROOM_TEACHER
    private Boolean isHomeroom;
    private Boolean isPhonePublic;
    private String status;
}
