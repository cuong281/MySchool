package com.jetbrains.grade.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class RewardDisciplineDTO {
    private Integer id;
    private UserDTO user;
    private String type;
    private String content;
    private String date;
    private String decisionNumber;

    @Data
    @Builder
    public static class UserDTO {
        private Integer id;
        private String username;
        private String className;
    }
}
