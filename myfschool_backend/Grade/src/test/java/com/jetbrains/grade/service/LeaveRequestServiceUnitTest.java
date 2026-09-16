package com.jetbrains.grade.service;

import com.jetbrains.grade.model.LeaveRequest;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.model.Teacher;
import com.jetbrains.grade.repository.LeaveRequestRepository;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.repository.TeacherRepository;
import com.jetbrains.grade.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import java.time.LocalDate;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Mockito unit tests for LeaveRequestService.create() — no Spring context.
 * Uses mockStatic for SecurityUtils static methods.
 */
@ExtendWith(MockitoExtension.class)
class LeaveRequestServiceUnitTest {

    @Mock private LeaveRequestRepository leaveRequestRepository;
    @Mock private StudentRepository studentRepository;
    @Mock private TeacherRepository teacherRepository;

    @InjectMocks
    private LeaveRequestService leaveRequestService;

    // ── Helper ────────────────────────────────────────────────────────

    private LeaveRequest buildValidRequest(String reason) {
        LeaveRequest req = new LeaveRequest();
        req.setFromDate(LocalDate.of(2026, 10, 1));
        req.setToDate(LocalDate.of(2026, 10, 3));
        req.setReason(reason != null ? reason : "Bị ốm cần nghỉ");
        return req;
    }

    // ── STUDENT HAPPY PATH ───────────────────────────────────────────

    @Test
    @DisplayName("Student creates leave request for themselves → saved with status 'Chờ duyệt'")
    void studentHappyPath() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentUserId).thenReturn(2);
            su.when(SecurityUtils::isStudent).thenReturn(true);
            su.when(SecurityUtils::isTeacher).thenReturn(false);
            su.when(SecurityUtils::isAdmin).thenReturn(false);

            Student student = new Student();
            student.setId(10);
            when(studentRepository.findByUserId(2)).thenReturn(Optional.of(student));
            when(leaveRequestRepository.save(any(LeaveRequest.class))).thenAnswer(inv -> {
                LeaveRequest lr = inv.getArgument(0);
                lr.setId(1);
                return lr;
            });

            LeaveRequest req = buildValidRequest(null);
            LeaveRequest result = leaveRequestService.create(req);

            assertNotNull(result.getId());
            assertEquals("Chờ duyệt", result.getStatus());
            assertEquals(student, result.getStudent());
            assertNull(result.getTeacher());
            assertEquals("Nghỉ học", result.getRequestType());
            verify(leaveRequestRepository).save(req);
        }
    }

    // ── STUDENT OWNERSHIP VIOLATION ──────────────────────────────────

    @Test
    @DisplayName("Student attempts leave request for another student → AccessDeniedException")
    void studentOwnershipViolation() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentUserId).thenReturn(2);
            su.when(SecurityUtils::isStudent).thenReturn(true);
            su.when(SecurityUtils::isTeacher).thenReturn(false);
            su.when(SecurityUtils::isAdmin).thenReturn(false);

            Student currentStudent = new Student();
            currentStudent.setId(10);
            when(studentRepository.findByUserId(2)).thenReturn(Optional.of(currentStudent));

            // Attempt to create for a different student
            Student otherStudent = new Student();
            otherStudent.setId(99);

            LeaveRequest req = buildValidRequest(null);
            req.setStudent(otherStudent);

            assertThrows(AccessDeniedException.class, () -> leaveRequestService.create(req));
            verify(leaveRequestRepository, never()).save(any());
        }
    }

    // ── TEACHER HAPPY PATH ───────────────────────────────────────────

    @Test
    @DisplayName("Teacher creates leave request for themselves → saved with status 'Chờ duyệt'")
    void teacherHappyPath() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentUserId).thenReturn(8);
            su.when(SecurityUtils::isStudent).thenReturn(false);
            su.when(SecurityUtils::isTeacher).thenReturn(true);
            su.when(SecurityUtils::isAdmin).thenReturn(false);

            Teacher teacher = new Teacher();
            teacher.setId(5);
            when(teacherRepository.findByUserId(8)).thenReturn(Optional.of(teacher));
            when(leaveRequestRepository.save(any(LeaveRequest.class))).thenAnswer(inv -> {
                LeaveRequest lr = inv.getArgument(0);
                lr.setId(2);
                return lr;
            });

            LeaveRequest req = buildValidRequest("Công việc cá nhân");
            LeaveRequest result = leaveRequestService.create(req);

            assertEquals("Chờ duyệt", result.getStatus());
            assertEquals(teacher, result.getTeacher());
            assertNull(result.getStudent());
            assertEquals("Nghỉ phép", result.getRequestType());
        }
    }

    // ── TEACHER OWNERSHIP VIOLATION ──────────────────────────────────

    @Test
    @DisplayName("Teacher attempts leave request for another teacher → AccessDeniedException")
    void teacherOwnershipViolation() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentUserId).thenReturn(8);
            su.when(SecurityUtils::isStudent).thenReturn(false);
            su.when(SecurityUtils::isTeacher).thenReturn(true);
            su.when(SecurityUtils::isAdmin).thenReturn(false);

            Teacher currentTeacher = new Teacher();
            currentTeacher.setId(5);
            when(teacherRepository.findByUserId(8)).thenReturn(Optional.of(currentTeacher));

            Teacher otherTeacher = new Teacher();
            otherTeacher.setId(99);

            LeaveRequest req = buildValidRequest("Lý do cá nhân");
            req.setTeacher(otherTeacher);

            assertThrows(AccessDeniedException.class, () -> leaveRequestService.create(req));
            verify(leaveRequestRepository, never()).save(any());
        }
    }

    // ── STUDENT NOT FOUND ────────────────────────────────────────────

    @Test
    @DisplayName("Student user has no student record → IllegalArgumentException")
    void studentNotFound() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentUserId).thenReturn(2);
            su.when(SecurityUtils::isStudent).thenReturn(true);
            su.when(SecurityUtils::isTeacher).thenReturn(false);
            su.when(SecurityUtils::isAdmin).thenReturn(false);

            when(studentRepository.findByUserId(2)).thenReturn(Optional.empty());

            LeaveRequest req = buildValidRequest(null);

            assertThrows(IllegalArgumentException.class, () -> leaveRequestService.create(req));
        }
    }

    // ── TEACHER NOT FOUND ────────────────────────────────────────────

    @Test
    @DisplayName("Teacher user has no teacher record → IllegalArgumentException")
    void teacherNotFound() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentUserId).thenReturn(8);
            su.when(SecurityUtils::isStudent).thenReturn(false);
            su.when(SecurityUtils::isTeacher).thenReturn(true);
            su.when(SecurityUtils::isAdmin).thenReturn(false);

            when(teacherRepository.findByUserId(8)).thenReturn(Optional.empty());

            LeaveRequest req = buildValidRequest("Lý do");

            assertThrows(IllegalArgumentException.class, () -> leaveRequestService.create(req));
        }
    }

    // ── DATE VALIDATION ──────────────────────────────────────────────

    @Test
    @DisplayName("fromDate after toDate → IllegalArgumentException")
    void fromDateAfterToDate() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentUserId).thenReturn(1);
            su.when(SecurityUtils::isStudent).thenReturn(false);
            su.when(SecurityUtils::isTeacher).thenReturn(false);
            su.when(SecurityUtils::isAdmin).thenReturn(true);

            LeaveRequest req = new LeaveRequest();
            req.setFromDate(LocalDate.of(2026, 10, 5));
            req.setToDate(LocalDate.of(2026, 10, 1));
            req.setReason("Lý do hợp lệ");

            assertThrows(IllegalArgumentException.class, () -> leaveRequestService.create(req));
        }
    }

    @Test
    @DisplayName("null fromDate → IllegalArgumentException")
    void nullFromDate() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentUserId).thenReturn(1);
            su.when(SecurityUtils::isStudent).thenReturn(false);
            su.when(SecurityUtils::isTeacher).thenReturn(false);
            su.when(SecurityUtils::isAdmin).thenReturn(true);

            LeaveRequest req = new LeaveRequest();
            req.setToDate(LocalDate.of(2026, 10, 3));
            req.setReason("Lý do hợp lệ");

            assertThrows(IllegalArgumentException.class, () -> leaveRequestService.create(req));
        }
    }

    // ── REASON VALIDATION ────────────────────────────────────────────

    @Test
    @DisplayName("reason shorter than 3 chars → IllegalArgumentException")
    void reasonTooShort() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentUserId).thenReturn(1);
            su.when(SecurityUtils::isStudent).thenReturn(false);
            su.when(SecurityUtils::isTeacher).thenReturn(false);
            su.when(SecurityUtils::isAdmin).thenReturn(true);

            LeaveRequest req = new LeaveRequest();
            req.setFromDate(LocalDate.of(2026, 10, 1));
            req.setToDate(LocalDate.of(2026, 10, 3));
            req.setReason("ab");

            assertThrows(IllegalArgumentException.class, () -> leaveRequestService.create(req));
        }
    }

    // ── ID RESET ─────────────────────────────────────────────────────

    @Test
    @DisplayName("ID is reset to null before save (mass-assignment protection)")
    void idResetBeforeSave() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentUserId).thenReturn(1);
            su.when(SecurityUtils::isStudent).thenReturn(false);
            su.when(SecurityUtils::isTeacher).thenReturn(false);
            su.when(SecurityUtils::isAdmin).thenReturn(true);

            when(leaveRequestRepository.save(any(LeaveRequest.class))).thenAnswer(inv -> inv.getArgument(0));

            LeaveRequest req = buildValidRequest("Lý do hợp lệ đầy đủ");
            req.setId(999); // attacker tries to set ID

            LeaveRequest result = leaveRequestService.create(req);
            assertNull(result.getId());
        }
    }
}
