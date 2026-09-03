package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.AuthResponse;
import com.jetbrains.grade.dto.LoginRequest;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.model.User;
import com.jetbrains.grade.model.Role;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    public AuthResponse login(LoginRequest request) {
        if (request.getPhoneNumber() == null || request.getPhoneNumber().isBlank()
                || request.getPassword() == null || request.getPassword().isBlank()) {
            throw new IllegalArgumentException("Vui long nhap day du so dien thoai va mat khau");
        }

        Optional<User> userOpt = userRepository.findByPhoneNumberAndIsActiveTrue(request.getPhoneNumber());

        if (userOpt.isEmpty()) {
            throw new RuntimeException("Sai so dien thoai hoac mat khau");
        }

        User user = userOpt.get();
        String storedHash = user.getPasswordHash() != null ? user.getPasswordHash().trim() : "";
        String inputPassword = request.getPassword() != null ? request.getPassword().trim() : "";

        if (!passwordEncoder.matches(inputPassword, storedHash)) {
            throw new RuntimeException("Sai so dien thoai hoac mat khau");
        }

        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);

        List<String> roleNames = user.getRoles().stream()
                .map(Role::getRoleName)
                .collect(Collectors.toList());

        Integer studentId = null;
        String studentCode = null;
        Integer classId = null;
        String className = null;

        // Neu co bat ky role nao la Student, thi lay thong tin Student
        if (roleNames.stream().anyMatch(r -> "Student".equalsIgnoreCase(r))) {
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

        return AuthResponse.builder()
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
                .message("Dang nhap thanh cong")
                .build();
    }
}
