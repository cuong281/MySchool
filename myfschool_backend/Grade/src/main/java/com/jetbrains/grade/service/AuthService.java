package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.AuthResponse;
import com.jetbrains.grade.dto.LoginRequest;
import com.jetbrains.grade.dto.RefreshTokenRequest;
import com.jetbrains.grade.model.RefreshToken;
import com.jetbrains.grade.model.Role;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.model.Teacher;
import com.jetbrains.grade.model.User;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.repository.TeacherRepository;
import com.jetbrains.grade.repository.UserRepository;
import com.jetbrains.grade.security.CustomUserDetailsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final RefreshTokenService refreshTokenService;
    private final CustomUserDetailsService userDetailsService;
    private final SecurityAuditService auditService;

    @Transactional
    public AuthResponse login(LoginRequest request) {
        if (request.getPhoneNumber() == null || request.getPhoneNumber().isBlank()
                || request.getPassword() == null || request.getPassword().isBlank()) {
            throw new IllegalArgumentException("Vui long nhap day du so dien thoai va mat khau");
        }

        // Support login by phone number or username
        String identifier = request.getPhoneNumber().trim();
        Optional<User> userOpt = userRepository.findByPhoneNumberAndIsActiveTrue(identifier)
                .or(() -> userRepository.findByUsername(identifier));

        if (userOpt.isEmpty()) {
            auditService.logSecurityEvent("LOGIN", null, identifier, List.of(), "AUTH", "FAILURE", "Nguoi dung khong ton tai");
            throw new RuntimeException("Sai so dien thoai hoac mat khau");
        }

        User user = userOpt.get();
        String storedHash = user.getPasswordHash() != null ? user.getPasswordHash().trim() : "";
        String inputPassword = request.getPassword() != null ? request.getPassword().trim() : "";

        if (!passwordEncoder.matches(inputPassword, storedHash)) {
            auditService.logSecurityEvent("LOGIN", user.getId(), user.getUsername(), List.of(), "AUTH", "FAILURE", "Sai mat khau");
            throw new RuntimeException("Sai so dien thoai hoac mat khau");
        }

        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);

        auditService.logSecurityEvent("LOGIN", user.getId(), user.getUsername(),
                user.getRoles().stream().map(Role::getRoleName).toList(), "AUTH", "SUCCESS", "Dang nhap thanh cong");

        return buildAuthResponse(user, "Dang nhap thanh cong");
    }

    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        if (request == null || request.getRefreshToken() == null || request.getRefreshToken().isBlank()) {
            throw new IllegalArgumentException("Refresh token khong duoc de trong");
        }

        RefreshToken refreshToken = refreshTokenService.verifyRefreshToken(request.getRefreshToken());
        User user = refreshToken.getUser();

        // Rotate refresh token
        String newRefreshToken = refreshTokenService.rotateRefreshToken(refreshToken);

        // Build new access token
        Integer studentId = null;
        Integer teacherId = null;

        if (user.getStudent() != null) {
            studentId = user.getStudent().getId();
        } else {
            Optional<Student> studentOpt = studentRepository.findByUserId(user.getId());
            if (studentOpt.isPresent()) studentId = studentOpt.get().getId();
        }

        if (user.getTeacher() != null) {
            teacherId = user.getTeacher().getId();
        } else {
            Optional<Teacher> teacherOpt = teacherRepository.findByUserId(user.getId());
            if (teacherOpt.isPresent()) teacherId = teacherOpt.get().getId();
        }

        UserDetails userDetails = userDetailsService.loadUserById(user.getId());
        String newAccessToken = jwtService.generateToken(userDetails, user.getId(), studentId, teacherId);

        List<String> roleNames = user.getRoles().stream()
                .map(Role::getRoleName)
                .collect(Collectors.toList());

        String studentCode = null;
        Integer classId = null;
        String className = null;

        if (studentId != null) {
            Optional<Student> studentOpt = studentRepository.findById(studentId);
            if (studentOpt.isPresent()) {
                Student student = studentOpt.get();
                studentCode = student.getStudentCode();
                if (student.getSchoolClass() != null) {
                    classId = student.getSchoolClass().getId();
                    className = student.getSchoolClass().getClassName();
                }
            }
        }

        return AuthResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(newRefreshToken)
                .tokenType("Bearer")
                .expiresIn(7200L) // 2 hours in seconds
                .userId(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .firstName(user.getFirstName() != null ? user.getFirstName() : "")
                .lastName(user.getLastName() != null ? user.getLastName() : "")
                .phoneNumber(user.getPhoneNumber() != null ? user.getPhoneNumber() : "")
                .roles(roleNames)
                .studentId(studentId)
                .studentCode(studentCode)
                .classId(classId)
                .className(className)
                .teacherId(teacherId)
                .message("Lam moi token thanh cong")
                .build();
    }

    @Transactional
    public void logout(RefreshTokenRequest request) {
        if (request != null && request.getRefreshToken() != null && !request.getRefreshToken().isBlank()) {
            refreshTokenService.revokeRefreshToken(request.getRefreshToken().trim());
        }
    }

    private AuthResponse buildAuthResponse(User user, String message) {
        List<String> roleNames = user.getRoles().stream()
                .map(Role::getRoleName)
                .collect(Collectors.toList());

        Integer studentId = null;
        String studentCode = null;
        Integer classId = null;
        String className = null;
        Integer teacherId = null;

        // Check student profile
        if (roleNames.stream().anyMatch(r -> "Student".equalsIgnoreCase(r) || "ROLE_STUDENT".equalsIgnoreCase(r))) {
            Optional<Student> studentOpt = studentRepository.findByUserId(user.getId());
            if (studentOpt.isPresent()) {
                Student student = studentOpt.get();
                studentId = student.getId();
                studentCode = student.getStudentCode();
                if (student.getSchoolClass() != null) {
                    classId = student.getSchoolClass().getId();
                    className = student.getSchoolClass().getClassName();
                }
            }
        }

        // Check teacher profile
        if (roleNames.stream().anyMatch(r -> "Teacher".equalsIgnoreCase(r) || "ROLE_TEACHER".equalsIgnoreCase(r))) {
            Optional<Teacher> teacherOpt = teacherRepository.findByUserId(user.getId());
            if (teacherOpt.isPresent()) {
                teacherId = teacherOpt.get().getId();
            }
        }

        // Generate tokens
        UserDetails userDetails = userDetailsService.loadUserById(user.getId());
        String accessToken = jwtService.generateToken(userDetails, user.getId(), studentId, teacherId);
        String refreshToken = refreshTokenService.createRefreshToken(user);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(7200L) // 2 hours in seconds
                .userId(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .firstName(user.getFirstName() != null ? user.getFirstName() : "")
                .lastName(user.getLastName() != null ? user.getLastName() : "")
                .phoneNumber(user.getPhoneNumber() != null ? user.getPhoneNumber() : "")
                .roles(roleNames)
                .studentId(studentId)
                .studentCode(studentCode)
                .classId(classId)
                .className(className)
                .teacherId(teacherId)
                .message(message)
                .build();
    }
}
