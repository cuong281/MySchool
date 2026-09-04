package com.jetbrains.grade;

import com.jetbrains.grade.model.Role;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.model.User;
import com.jetbrains.grade.security.CustomUserDetails;
import com.jetbrains.grade.security.SecurityUtils;
import com.jetbrains.grade.service.GradeService;
import com.jetbrains.grade.service.LeaveRequestService;
import com.jetbrains.grade.service.ScheduleService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class IdorSecurityTest {

    @Autowired
    private GradeService gradeService;

    @Autowired
    private LeaveRequestService leaveRequestService;

    @Autowired
    private ScheduleService scheduleService;

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
            com.jetbrains.grade.model.Teacher teacher = new com.jetbrains.grade.model.Teacher();
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
    public void testSecurityUtilsDetectsRolesCorrectly() {
        authenticateUser(1, "admin", "Admin", null, null);
        assertTrue(SecurityUtils.isAdmin());
        assertFalse(SecurityUtils.isStudent());
        assertFalse(SecurityUtils.isTeacher());
        assertEquals(1, SecurityUtils.getCurrentUserId());

        authenticateUser(2, "student_a", "Student", 1, null);
        assertFalse(SecurityUtils.isAdmin());
        assertTrue(SecurityUtils.isStudent());
        assertFalse(SecurityUtils.isTeacher());
        assertEquals(2, SecurityUtils.getCurrentUserId());
        assertEquals(1, SecurityUtils.getCurrentStudentId());

        authenticateUser(8, "teacher_han", "Teacher", null, 1);
        assertFalse(SecurityUtils.isAdmin());
        assertFalse(SecurityUtils.isStudent());
        assertTrue(SecurityUtils.isTeacher());
        assertEquals(8, SecurityUtils.getCurrentUserId());
        assertEquals(1, SecurityUtils.getCurrentTeacherId());
    }

    @Test
    public void testStudentCannotAccessOtherStudentGrades() {
        // Authenticate as Student A (userId = 2, studentId = 1)
        authenticateUser(2, "student_a", "Student", 1, null);

        // Student A queries own grades (userId = 2) -> Allowed
        assertDoesNotThrow(() -> gradeService.getByUserId(2));

        // Student A queries Student B's grades (userId = 3) -> Throws AccessDeniedException
        assertThrows(AccessDeniedException.class, () -> gradeService.getByUserId(3));

        // Student A calls getAll() -> Throws AccessDeniedException
        assertThrows(AccessDeniedException.class, () -> gradeService.getAll());

        // Student A calls getByClassId() -> Throws AccessDeniedException
        assertThrows(AccessDeniedException.class, () -> gradeService.getByClassId(1));
    }

    @Test
    public void testStudentCannotAccessOtherStudentLeaveRequests() {
        // Authenticate as Student A (userId = 2, studentId = 1)
        authenticateUser(2, "student_a", "Student", 1, null);

        // Student A queries own leave requests (userId = 2) -> Allowed
        assertDoesNotThrow(() -> leaveRequestService.getByUserId(2));

        // Student A queries Student B's leave requests (userId = 3) -> Throws AccessDeniedException
        assertThrows(AccessDeniedException.class, () -> leaveRequestService.getByUserId(3));

        // Student A calls getAll() -> Throws AccessDeniedException
        assertThrows(AccessDeniedException.class, () -> leaveRequestService.getAll());

        // Student A calls updateStatus() -> Throws AccessDeniedException
        assertThrows(AccessDeniedException.class, () -> leaveRequestService.updateStatus(1, "Đã duyệt", "Fake note"));
    }

    @Test
    public void testStudentCannotAccessOtherStudentSchedule() {
        // Authenticate as Student A (userId = 2, studentId = 1)
        authenticateUser(2, "student_a", "Student", 1, null);

        // Student A queries Student B's schedule (userId = 3) -> Throws AccessDeniedException
        assertThrows(AccessDeniedException.class, () -> scheduleService.getStudentScheduleByUserId(3));
    }

    @Test
    public void testTeacherCanViewOwnTeachingSchedule() {
        // Authenticate as Teacher 1 (userId = 8, teacherId = 1)
        authenticateUser(8, "teacher_han", "Teacher", null, 1);

        assertDoesNotThrow(() -> {
            var mySchedule = scheduleService.getMySchedule();
            assertNotNull(mySchedule);
            assertFalse(mySchedule.isEmpty());
            // Verify periods contain className
            var firstPeriod = mySchedule.get(0).getPeriods().get(0);
            assertNotNull(firstPeriod.getClassName());
        });

        assertDoesNotThrow(() -> scheduleService.getTeacherSchedule(1));
    }

    @Test
    public void testTeacherCannotViewOtherTeacherTeachingSchedule() {
        // Authenticate as Teacher 1 (userId = 8, teacherId = 1)
        authenticateUser(8, "teacher_han", "Teacher", null, 1);

        // Teacher 1 queries Teacher 2's schedule -> Throws AccessDeniedException
        assertThrows(AccessDeniedException.class, () -> scheduleService.getTeacherSchedule(2));
    }

    @Test
    public void testAdminCanViewAnyTeacherAndClassSchedule() {
        // Authenticate as Admin (userId = 1)
        authenticateUser(1, "admin", "Admin", null, null);

        // Admin can view Teacher 1 and Teacher 2 teaching schedules
        assertDoesNotThrow(() -> scheduleService.getTeacherSchedule(1));
        assertDoesNotThrow(() -> scheduleService.getTeacherSchedule(2));

        // Admin can view Class 1 and Class 2 schedules
        assertDoesNotThrow(() -> scheduleService.getScheduleByClassId(1));
        assertDoesNotThrow(() -> scheduleService.getScheduleByClassId(2));
    }

    @Test
    public void testAdminCanAccessAllGradesAndLeaveRequests() {
        // Authenticate as Admin (userId = 1)
        authenticateUser(1, "admin", "Admin", null, null);

        // Admin can call getAll() on grades and leave requests
        assertDoesNotThrow(() -> gradeService.getAll());
        assertDoesNotThrow(() -> leaveRequestService.getAll());

        // Admin can query any student's grades
        assertDoesNotThrow(() -> gradeService.getByUserId(2));
        assertDoesNotThrow(() -> gradeService.getByUserId(3));
    }
}
