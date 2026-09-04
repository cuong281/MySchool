package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthResponse {
    // JWT Tokens
    private String accessToken;
    private String refreshToken;
    @Builder.Default
    private String tokenType = "Bearer";
    private Long expiresIn; // in seconds

    // User details (backward-compatible with existing client)
    private Integer userId;
    private String username;
    private String email;
    private String firstName;
    private String lastName;
    private String phoneNumber;
    private List<String> roles;

    // Student profile (if student)
    private Integer studentId;
    private String studentCode;
    private Integer classId;
    private String className;

    // Teacher profile (if teacher)
    private Integer teacherId;

    private String message;
}
