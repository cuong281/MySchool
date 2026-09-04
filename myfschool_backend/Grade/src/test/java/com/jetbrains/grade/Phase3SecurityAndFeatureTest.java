package com.jetbrains.grade;

import com.jetbrains.grade.dto.AttendanceCreateRequest;
import com.jetbrains.grade.dto.AttendanceRecordDTO;
import com.jetbrains.grade.dto.AttendanceSummaryDTO;
import com.jetbrains.grade.dto.NotificationDTO;
import com.jetbrains.grade.model.*;
import com.jetbrains.grade.repository.AttendanceRepository;
import com.jetbrains.grade.repository.NotificationRepository;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.repository.UserRepository;
import com.jetbrains.grade.security.CustomUserDetails;
import com.jetbrains.grade.service.AttendanceService;
import com.jetbrains.grade.service.GradeService;
import com.jetbrains.grade.service.LeaveRequestService;
import com.jetbrains.grade.service.NotificationService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class Phase3SecurityAndFeatureTest {

    @Autowired
    private AttendanceService attendanceService;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private LeaveRequestService leaveRequestService;

    @Autowired
    private GradeService gradeService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private StudentRepository studentRepository;

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @AfterEach
    public void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private void authenticateUser(int userId, String username, String roleName, Integer studentId, Integer teacherId) {
        Role role = new Role();
        role.setId(roleName.equals("Admin") ? 1 : (roleName.equals("Teacher") ? 4 : 3));
        role.setRoleName(roleName);
        role.setIsActive(true);

        User user = new User();
        user.setId(userId);
        user.setUsername(username);
        user.setPasswordHash("hashed_dummy");
        user.setPhoneNumber("090" + userId + "000000");
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

        CustomUserDetails userDetails = new CustomUserDetails(user);
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                userDetails, null, userDetails.getAuthorities()
        );
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    public void testStudentCannotRecordAttendance() {
        // Authenticate as Student A (userId = 2, studentId = 1)
        authenticateUser(2, "student_a", "Student", 1, null);

        AttendanceCreateRequest req = new AttendanceCreateRequest(
                1, 1, 1, LocalDate.now(), 1, "PRESENT", "Test note"
        );

        // Student recording attendance must throw AccessDeniedException
        assertThrows(AccessDeniedException.class, () -> attendanceService.recordAttendance(req));
    }

    @Test
    public void testStudentCannotViewOtherStudentAttendance() {
        // Authenticate as Student A (userId = 2, studentId = 1)
        authenticateUser(2, "student_a", "Student", 1, null);

        // Student A accesses own attendance -> OK
        assertDoesNotThrow(() -> attendanceService.getStudentAttendance(1));
        assertDoesNotThrow(() -> attendanceService.getStudentAttendanceSummary(1));

        // Student A accesses Student B (studentId = 2) -> AccessDeniedException (IDOR)
        assertThrows(AccessDeniedException.class, () -> attendanceService.getStudentAttendance(2));
        assertThrows(AccessDeniedException.class, () -> attendanceService.getStudentAttendanceSummary(2));
    }

    @Test
    public void testAttendanceSummaryFormula() {
        // Calculate summary for student 1
        AttendanceSummaryDTO summary = attendanceService.calculateSummary(1);
        assertNotNull(summary);
        assertEquals(1, summary.getStudentId());
        assertTrue(summary.getAttendanceRate() >= 0.0 && summary.getAttendanceRate() <= 100.0);
        assertNotNull(summary.getStatusNote());
    }

    @Test
    @Transactional
    public void testTeacherCanRecordAttendance() {
        // Authenticate as Teacher (userId = 8, teacherId = 1)
        authenticateUser(8, "teacher_han", "Teacher", null, 1);

        AttendanceCreateRequest req = new AttendanceCreateRequest(
                1, 1, 1, LocalDate.now().minusDays(1), 1, "PRESENT", "Verified present"
        );

        AttendanceRecordDTO result = attendanceService.recordAttendance(req);
        assertNotNull(result);
        assertEquals("PRESENT", result.getStatus());
    }

    @Test
    @Transactional
    public void testNotificationOwnershipAndMarkAsRead() {
        User user1 = userRepository.findByIdAndIsActiveTrue(1).orElseThrow();
        User user2 = userRepository.findByIdAndIsActiveTrue(2).orElseThrow();

        // Create notification for User 2 (Student A)
        Notification n = notificationService.createNotification(
                user2, "Test Title", "Test Content", "SYSTEM", null
        );
        assertNotNull(n.getId());
        assertFalse(n.getIsRead());

        // Authenticate as User 1 (Admin) - Admin is allowed or Student 2
        // If authenticate as Student B (userId = 3)
        authenticateUser(3, "student_b", "Student", 2, null);

        // Student B tries to mark Student A's notification as read -> AccessDeniedException
        assertThrows(AccessDeniedException.class, () -> notificationService.markAsRead(n.getId()));

        // Authenticate as Student A (userId = 2)
        authenticateUser(2, "student_a", "Student", 1, null);

        // Student A marks own notification as read -> Success
        NotificationDTO readResult = notificationService.markAsRead(n.getId());
        assertTrue(readResult.getIsRead());
    }
}
