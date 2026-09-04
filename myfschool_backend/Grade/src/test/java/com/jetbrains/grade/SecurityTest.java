package com.jetbrains.grade;

import com.jetbrains.grade.model.Role;
import com.jetbrains.grade.model.User;
import com.jetbrains.grade.security.CustomUserDetails;
import com.jetbrains.grade.service.JwtService;
import com.jetbrains.grade.service.RefreshTokenService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class SecurityTest {

    @Autowired
    private JwtService jwtService;

    @Autowired
    private RefreshTokenService refreshTokenService;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Test
    public void testBCryptPasswordEncoder() {
        String rawPassword123 = "123";
        String rawPassword123456 = "123456";

        String hash123 = passwordEncoder.encode(rawPassword123);
        String hash123456 = passwordEncoder.encode(rawPassword123456);

        assertTrue(passwordEncoder.matches("123", hash123));
        assertTrue(passwordEncoder.matches("123456", hash123456));
        assertFalse(passwordEncoder.matches("wrongpass", hash123));
        assertTrue(passwordEncoder.matches("123456", "$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi"));
    }

    @Test
    public void testJwtGenerationAndValidation() {
        Role studentRole = new Role();
        studentRole.setId(2);
        studentRole.setRoleName("Student");
        studentRole.setIsActive(true);
        User user = new User();
        user.setId(2);
        user.setUsername("nguyenvana");
        user.setPasswordHash(passwordEncoder.encode("123"));
        user.setPhoneNumber("0901111111");
        user.setEmail("nguyenvana@myfschool.vn");
        user.setIsActive(true);
        user.setRoles(Set.of(studentRole));

        CustomUserDetails userDetails = new CustomUserDetails(user);

        // Generate token
        String token = jwtService.generateToken(userDetails, user.getId(), 1, null);
        assertNotNull(token);
        assertFalse(token.isBlank());

        // Validate token
        assertTrue(jwtService.isTokenValid(token, userDetails));
        assertFalse(jwtService.isTokenExpired(token));

        // Validate extracted claims
        assertEquals("nguyenvana", jwtService.extractUsername(token));
        assertEquals(2, jwtService.extractUserId(token));
        assertTrue(jwtService.extractRoles(token).contains("ROLE_STUDENT"));
    }

    @Test
    public void testRefreshTokenHashing() {
        String token1 = "raw-refresh-token-value-12345";
        String hash1 = refreshTokenService.hashToken(token1);
        String hash2 = refreshTokenService.hashToken(token1);

        assertNotNull(hash1);
        assertEquals(hash1, hash2); // Deterministic SHA-256
        assertNotEquals(token1, hash1); // Not plaintext
        assertEquals(64, hash1.length()); // SHA-256 hex is 64 chars
    }

    @Test
    public void testTeacherUserDetailsAuthorities() {
        Role teacherRole = new Role();
        teacherRole.setId(3);
        teacherRole.setRoleName("Teacher");
        teacherRole.setIsActive(true);
        User user = new User();
        user.setId(8);
        user.setUsername("teacher_han");
        user.setPasswordHash(passwordEncoder.encode("123456"));
        user.setPhoneNumber("0901000001");
        user.setEmail("han@myfschool.vn");
        user.setIsActive(true);
        user.setRoles(Set.of(teacherRole));

        CustomUserDetails userDetails = new CustomUserDetails(user);

        assertTrue(userDetails.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_TEACHER")));
    }
}
