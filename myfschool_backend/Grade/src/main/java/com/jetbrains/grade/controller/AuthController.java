package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.AuthResponse;
import com.jetbrains.grade.dto.LoginRequest;
import com.jetbrains.grade.dto.RefreshTokenRequest;
import com.jetbrains.grade.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "Đăng nhập, làm mới token và đăng xuất")
public class AuthController {

    private final AuthService authService;

    @Operation(summary = "Đăng nhập hệ thống", description = "Xác thực bằng số điện thoại/username và mật khẩu, trả về Access Token JWT và Refresh Token.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Đăng nhập thành công"),
            @ApiResponse(responseCode = "400", description = "Thiếu thông tin đăng nhập"),
            @ApiResponse(responseCode = "401", description = "Sai số điện thoại hoặc mật khẩu")
    })
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            AuthResponse response = authService.login(request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", e.getMessage()));
        }
    }

    @Operation(summary = "Làm mới Access Token", description = "Sử dụng Refresh Token hợp lệ để cấp Access Token mới.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Làm mới token thành công"),
            @ApiResponse(responseCode = "401", description = "Refresh Token không hợp lệ hoặc đã hết hạn")
    })
    @PostMapping("/refresh-token")
    public ResponseEntity<?> refreshToken(@RequestBody RefreshTokenRequest request) {
        try {
            AuthResponse response = authService.refreshToken(request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    @Operation(summary = "Đăng xuất", description = "Thu hồi Refresh Token và vô hiệu hóa phiên đăng nhập.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Đăng xuất thành công")
    })
    @PostMapping("/logout")
    public ResponseEntity<?> logout(@RequestBody(required = false) RefreshTokenRequest request) {
        try {
            authService.logout(request);
            return ResponseEntity.ok(Map.of("message", "Dang xuat thanh cong"));
        } catch (Exception e) {
            return ResponseEntity.ok(Map.of("message", "Dang xuat thanh cong"));
        }
    }
}
