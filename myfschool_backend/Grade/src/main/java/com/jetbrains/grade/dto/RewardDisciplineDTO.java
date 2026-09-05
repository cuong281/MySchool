package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RewardDisciplineDTO {
    private Integer id;
    private UserDTO user;
    private String type;
    private String typeName;
    private String content;
    private String date;
    private String decisionNumber;
    private Integer semester;
    private String schoolYear;
    private String studentCode;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserDTO {
        private Integer id;
        private Integer studentId;
        private String username;
        private String className;
        private Integer classId;
    }
}

