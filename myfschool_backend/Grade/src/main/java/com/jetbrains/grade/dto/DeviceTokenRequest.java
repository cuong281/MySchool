package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DeviceTokenRequest {
    private String deviceToken;
    private String deviceType = "ANDROID";
}
