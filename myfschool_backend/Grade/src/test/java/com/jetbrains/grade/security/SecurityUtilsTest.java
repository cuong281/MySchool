package com.jetbrains.grade.security;

import com.jetbrains.grade.model.Role;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.model.Teacher;
import com.jetbrains.grade.model.User;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for SecurityUtils — no Spring context required.
 * Sets SecurityContextHolder manually for each test.
 */
class SecurityUtilsTest {

    @AfterEach
    void clearContext() {
        SecurityContextHolder.clearContext();
    }

    // ── Helper ────────────────────────────────────────────────────────

    private void authenticateAs(int userId, String username, String roleName,
                                Integer studentId, Integer teacherId) {
        Role role = new Role();
        role.setId(1);
        role.setRoleName(roleName);
        role.setIsActive(true);

        User user = new User();
        user.setId(userId);
        user.setUsername(username);
        user.setPasswordHash("dummy");
        user.setIsActive(true);
        user.setRoles(Set.of(role));

        if (studentId != null) {
            Student student = new Student();
            student.setId(studentId);
            student.setUser(user);
            user.setStudent(student);
        }

        if (teacherId != null) {
            Teacher teacher = new Teacher();
            teacher.setId(teacherId);
            teacher.setUser(user);
            user.setTeacher(teacher);
        }

        CustomUserDetails details = new CustomUserDetails(user);
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(details, null, details.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // ── Authenticated user identity extraction ───────────────────────

    @Test
    @DisplayName("getCurrentUserId returns the authenticated user's ID")
    void getCurrentUserId_authenticated() {
        authenticateAs(42, "admin", "Admin", null, null);
        assertEquals(42, SecurityUtils.getCurrentUserId());
    }

    @Test
    @DisplayName("getCurrentUsername returns the authenticated username")
    void getCurrentUsername_authenticated() {
        authenticateAs(1, "admin", "Admin", null, null);
        assertEquals("admin", SecurityUtils.getCurrentUsername());
    }

    @Test
    @DisplayName("getCurrentStudentId returns studentId when present")
    void getCurrentStudentId_present() {
        authenticateAs(2, "nguyenvana", "Student", 10, null);
        assertEquals(10, SecurityUtils.getCurrentStudentId());
    }

    @Test
    @DisplayName("getCurrentStudentId returns null when user has no student")
    void getCurrentStudentId_absent() {
        authenticateAs(1, "admin", "Admin", null, null);
        assertNull(SecurityUtils.getCurrentStudentId());
    }

    @Test
    @DisplayName("getCurrentTeacherId returns teacherId when present")
    void getCurrentTeacherId_present() {
        authenticateAs(8, "teacher_han", "Teacher", null, 5);
        assertEquals(5, SecurityUtils.getCurrentTeacherId());
    }

    @Test
    @DisplayName("getCurrentTeacherId returns null when user has no teacher")
    void getCurrentTeacherId_absent() {
        authenticateAs(1, "admin", "Admin", null, null);
        assertNull(SecurityUtils.getCurrentTeacherId());
    }

    // ── Unauthenticated ──────────────────────────────────────────────

    @Test
    @DisplayName("getCurrentUserId throws AccessDeniedException when unauthenticated")
    void getCurrentUserId_unauthenticated_throws() {
        assertThrows(AccessDeniedException.class, SecurityUtils::getCurrentUserId);
    }

    @Test
    @DisplayName("getCurrentUsername returns null when unauthenticated")
    void getCurrentUsername_unauthenticated() {
        assertNull(SecurityUtils.getCurrentUsername());
    }

    @Test
    @DisplayName("getCurrentUserDetails returns null when unauthenticated")
    void getCurrentUserDetails_unauthenticated() {
        assertNull(SecurityUtils.getCurrentUserDetails());
    }

    // ── Role checks ──────────────────────────────────────────────────

    @Test
    @DisplayName("isAdmin returns true for Admin role")
    void isAdmin_true() {
        authenticateAs(1, "admin", "Admin", null, null);
        assertTrue(SecurityUtils.isAdmin());
        assertFalse(SecurityUtils.isTeacher());
        assertFalse(SecurityUtils.isStudent());
    }

    @Test
    @DisplayName("isTeacher returns true for Teacher role")
    void isTeacher_true() {
        authenticateAs(8, "teacher_han", "Teacher", null, 5);
        assertTrue(SecurityUtils.isTeacher());
        assertFalse(SecurityUtils.isAdmin());
        assertFalse(SecurityUtils.isStudent());
    }

    @Test
    @DisplayName("isStudent returns true for Student role")
    void isStudent_true() {
        authenticateAs(2, "nguyenvana", "Student", 10, null);
        assertTrue(SecurityUtils.isStudent());
        assertFalse(SecurityUtils.isAdmin());
        assertFalse(SecurityUtils.isTeacher());
    }

    @Test
    @DisplayName("hasRole is case-insensitive")
    void hasRole_caseInsensitive() {
        authenticateAs(1, "admin", "Admin", null, null);
        assertTrue(SecurityUtils.hasRole("ROLE_ADMIN"));
        assertTrue(SecurityUtils.hasRole("role_admin"));
    }

    @Test
    @DisplayName("role checks return false when unauthenticated")
    void roleChecks_unauthenticated() {
        assertFalse(SecurityUtils.isAdmin());
        assertFalse(SecurityUtils.isTeacher());
        assertFalse(SecurityUtils.isStudent());
    }

    // ── Ownership assertions ─────────────────────────────────────────

    @Test
    @DisplayName("assertUserOwnerOrAdmin passes for admin regardless of target user")
    void assertUserOwnerOrAdmin_admin() {
        authenticateAs(1, "admin", "Admin", null, null);
        assertDoesNotThrow(() -> SecurityUtils.assertUserOwnerOrAdmin(999, null));
    }

    @Test
    @DisplayName("assertUserOwnerOrAdmin passes when userId matches")
    void assertUserOwnerOrAdmin_ownId() {
        authenticateAs(2, "nguyenvana", "Student", 10, null);
        assertDoesNotThrow(() -> SecurityUtils.assertUserOwnerOrAdmin(2, null));
    }

    @Test
    @DisplayName("assertUserOwnerOrAdmin throws for non-admin non-owner")
    void assertUserOwnerOrAdmin_forbidden() {
        authenticateAs(2, "nguyenvana", "Student", 10, null);
        assertThrows(AccessDeniedException.class,
                () -> SecurityUtils.assertUserOwnerOrAdmin(99, "not allowed"));
    }

    @Test
    @DisplayName("assertStudentOwnerOrAdmin passes for admin")
    void assertStudentOwnerOrAdmin_admin() {
        authenticateAs(1, "admin", "Admin", null, null);
        assertDoesNotThrow(() -> SecurityUtils.assertStudentOwnerOrAdmin(999, null));
    }

    @Test
    @DisplayName("assertStudentOwnerOrAdmin passes when studentId matches")
    void assertStudentOwnerOrAdmin_ownStudent() {
        authenticateAs(2, "nguyenvana", "Student", 10, null);
        assertDoesNotThrow(() -> SecurityUtils.assertStudentOwnerOrAdmin(10, null));
    }

    @Test
    @DisplayName("assertStudentOwnerOrAdmin throws for non-admin non-owner")
    void assertStudentOwnerOrAdmin_forbidden() {
        authenticateAs(2, "nguyenvana", "Student", 10, null);
        assertThrows(AccessDeniedException.class,
                () -> SecurityUtils.assertStudentOwnerOrAdmin(99, "not allowed"));
    }
}
