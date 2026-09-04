package com.jetbrains.grade.security;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Centralized utility class for extracting current authenticated identity
 * and checking roles & ownership from Spring SecurityContext.
 */
public final class SecurityUtils {

    private SecurityUtils() {
        // Utility class
    }

    public static CustomUserDetails getCurrentUserDetails() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof CustomUserDetails) {
            return (CustomUserDetails) authentication.getPrincipal();
        }
        return null;
    }

    public static Integer getCurrentUserId() {
        CustomUserDetails userDetails = getCurrentUserDetails();
        if (userDetails != null) {
            return userDetails.getUserId();
        }
        throw new AccessDeniedException("Khong tim thay thong tin xac thuc nguoi dung");
    }

    public static String getCurrentUsername() {
        CustomUserDetails userDetails = getCurrentUserDetails();
        return userDetails != null ? userDetails.getUsername() : null;
    }

    public static Integer getCurrentStudentId() {
        CustomUserDetails userDetails = getCurrentUserDetails();
        return userDetails != null ? userDetails.getStudentId() : null;
    }

    public static Integer getCurrentTeacherId() {
        CustomUserDetails userDetails = getCurrentUserDetails();
        return userDetails != null ? userDetails.getTeacherId() : null;
    }

    public static List<String> getCurrentRoles() {
        CustomUserDetails userDetails = getCurrentUserDetails();
        if (userDetails != null && userDetails.getAuthorities() != null) {
            return userDetails.getAuthorities().stream()
                    .map(GrantedAuthority::getAuthority)
                    .collect(Collectors.toList());
        }
        return Collections.emptyList();
    }

    public static boolean isAdmin() {
        return hasRole("ROLE_ADMIN");
    }

    public static boolean isTeacher() {
        return hasRole("ROLE_TEACHER");
    }

    public static boolean isStudent() {
        return hasRole("ROLE_STUDENT");
    }

    public static boolean hasRole(String roleName) {
        CustomUserDetails userDetails = getCurrentUserDetails();
        if (userDetails != null && userDetails.getAuthorities() != null) {
            return userDetails.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equalsIgnoreCase(roleName));
        }
        return false;
    }

    /**
     * Asserts that current user is an Admin, or their UserID matches targetUserId.
     * Throws AccessDeniedException (HTTP 403) if unauthorized.
     */
    public static void assertUserOwnerOrAdmin(Integer targetUserId, String message) {
        if (isAdmin()) {
            return;
        }
        Integer currentUserId = getCurrentUserId();
        if (targetUserId == null || !targetUserId.equals(currentUserId)) {
            throw new AccessDeniedException(message != null ? message : "Ban khong co quyen truy cap tai nguyen cua nguoi dung khac");
        }
    }

    /**
     * Asserts that current user is an Admin, or their StudentID matches targetStudentId.
     * Throws AccessDeniedException (HTTP 403) if unauthorized.
     */
    public static void assertStudentOwnerOrAdmin(Integer targetStudentId, String message) {
        if (isAdmin()) {
            return;
        }
        Integer currentStudentId = getCurrentStudentId();
        if (targetStudentId == null || !targetStudentId.equals(currentStudentId)) {
            throw new AccessDeniedException(message != null ? message : "Ban khong co quyen truy cap du lieu cua hoc sinh khac");
        }
    }
}
