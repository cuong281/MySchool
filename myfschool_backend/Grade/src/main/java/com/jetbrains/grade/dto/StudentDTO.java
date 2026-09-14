package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudentDTO {
    private Integer id;
    private String studentCode;
    private String fullName;
    private Integer classId;
    private String className;
    private String gender;
    private LocalDate dateOfBirth;
}
