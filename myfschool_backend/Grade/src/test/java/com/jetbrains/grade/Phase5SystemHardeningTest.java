package com.jetbrains.grade;

import com.jetbrains.grade.dto.AdminDashboardDTO;
import com.jetbrains.grade.dto.TeacherHomeroomDashboardDTO;
import com.jetbrains.grade.dto.TeacherSubjectStatsDTO;
import com.jetbrains.grade.exception.ErrorResponse;
import com.jetbrains.grade.exception.GlobalExceptionHandler;
import com.jetbrains.grade.model.*;
import com.jetbrains.grade.repository.GradeRepository;
import com.jetbrains.grade.security.CustomUserDetails;
import com.jetbrains.grade.service.ContactService;
import com.jetbrains.grade.service.GradeService;
import com.jetbrains.grade.service.LeaveRequestService;
import com.jetbrains.grade.service.ReportService;
import com.jetbrains.grade.service.RewardDisciplineService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class Phase5SystemHardeningTest {

    @Autowired
    private ReportService reportService;

    @Autowired
    private GradeService gradeService;

    @Autowired
    private LeaveRequestService leaveRequestService;

    @Autowired
    private ContactService contactService;

    @Autowired
    private RewardDisciplineService rewardDisciplineService;

    @Autowired
    private GradeRepository gradeRepository;

    @Autowired
    private GlobalExceptionHandler exceptionHandler;

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
    public void testGlobalExceptionHandler_AccessDenied_Returns403() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/grades/1");

        AccessDeniedException ex = new AccessDeniedException("Khong co quyen");
        ResponseEntity<ErrorResponse> response = exceptionHandler.handleAccessDeniedException(ex, request);

        assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(403, response.getBody().getStatus());
        assertEquals("Forbidden", response.getBody().getError());
        assertEquals("Khong co quyen", response.getBody().getMessage());
        assertEquals("/api/grades/1", response.getBody().getPath());
        assertNotNull(response.getBody().getTimestamp());
    }

    @Test
    public void testGlobalExceptionHandler_IllegalArgument_Returns400() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/grades");

        IllegalArgumentException ex = new IllegalArgumentException("Diem so ngoai khoang hop le");
        ResponseEntity<ErrorResponse> response = exceptionHandler.handleBadRequestException(ex, request);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(400, response.getBody().getStatus());
        assertEquals("Bad Request", response.getBody().getError());
        assertEquals("Diem so ngoai khoang hop le", response.getBody().getMessage());
        assertEquals("/api/grades", response.getBody().getPath());
    }

    @Test
    public void testAdminDashboard_AdminAccess_Success() {
        // Authenticate as Admin (UserID 1)
        authenticateUser(1, "admin", "Admin", null, null);

        AdminDashboardDTO dashboard = reportService.getAdminDashboard();
        assertNotNull(dashboard);
        assertTrue(dashboard.getTotalStudents() > 0, "Total students should be greater than 0");
        assertTrue(dashboard.getTotalTeachers() > 0, "Total teachers should be greater than 0");
        assertTrue(dashboard.getTotalClasses() > 0, "Total classes should be greater than 0");
        assertNotNull(dashboard.getGradeDistribution(), "Grade distribution map should not be null");
        assertNotNull(dashboard.getAttendanceRate(), "Attendance rate should not be null");
    }

    @Test
    public void testAdminDashboard_NonAdminAccess_ThrowsAccessDenied() {
        // Authenticate as Student (UserID 2)
        authenticateUser(2, "student_a", "Student", 1, null);

        assertThrows(AccessDeniedException.class, () -> {
            reportService.getAdminDashboard();
        });
    }

    @Test
    public void testTeacherHomeroomDashboard_HomeroomTeacher_Success() {
        // Teacher 1 (UserID 8, TeacherID 1) is Homeroom of Class 1 (10A1)
        authenticateUser(8, "teacher_han", "Teacher", null, 1);

        TeacherHomeroomDashboardDTO dashboard = reportService.getTeacherHomeroomDashboard();
        assertNotNull(dashboard);
        assertEquals(1, dashboard.getClassId());
        assertTrue(dashboard.getTotalStudents() > 0);
        assertNotNull(dashboard.getAttendanceRate());
    }

    @Test
    public void testTeacherHomeroomDashboard_NonHomeroomTeacher_ThrowsAccessDenied() {
        // Teacher 3 (UserID 10, TeacherID 3) is NOT a homeroom teacher
        authenticateUser(10, "teacher_duong", "Teacher", null, 3);

        assertThrows(AccessDeniedException.class, () -> {
            reportService.getTeacherHomeroomDashboard();
        });
    }

    @Test
    public void testTeacherSubjectStats_SubjectTeacher_Success() {
        // Teacher 1 (TeacherID 1) teaches Subject 1 (Math) in Class 1
        authenticateUser(8, "teacher_han", "Teacher", null, 1);

        TeacherSubjectStatsDTO stats = reportService.getTeacherSubjectStats(1, 1);
        assertNotNull(stats);
        assertEquals(1, stats.getClassId());
        assertEquals(1, stats.getSubjectId());
        assertNotNull(stats.getAverageScore());
    }

    @Test
    public void testGradeValidation_OutOfRange_ThrowsIllegalArgument() {
        // Teacher 1 teaches Math (Subject 1) to Student 1 (Class 1)
        authenticateUser(8, "teacher_han", "Teacher", null, 1);

        List<Grade> grades = gradeRepository.findByStudentId(1);
        assertFalse(grades.isEmpty());
        Grade target = grades.get(0);

        // Try updating with score 15.0 (> 10.0)
        Grade invalidData = new Grade();
        invalidData.setAttendanceScore(10.0);
        invalidData.setMidtermScore(15.0); // INVALID!
        invalidData.setFinalScore(9.0);

        assertThrows(IllegalArgumentException.class, () -> {
            gradeService.update(target.getId(), invalidData);
        });
    }

    @Test
    @Transactional
    public void testLeaveRequestValidation_InvalidDateRange_ThrowsIllegalArgument() {
        // Student 1 (UserID 2, StudentID 1)
        authenticateUser(2, "student_a", "Student", 1, null);

        LeaveRequest invalidReq = new LeaveRequest();
        invalidReq.setFromDate(LocalDate.now().plusDays(5));
        invalidReq.setToDate(LocalDate.now().plusDays(2)); // INVALID: fromDate is after toDate!
        invalidReq.setReason("Em xin nghỉ phép đi du lịch");

        assertThrows(IllegalArgumentException.class, () -> {
            leaveRequestService.create(invalidReq);
        });
    }

    @Test
    public void testContactService_StudentIdor_ThrowsAccessDenied() {
        // Student 1 (UserID 2) attempting to read contacts of User 3 (Student 2)
        authenticateUser(2, "student_a", "Student", 1, null);

        assertThrows(AccessDeniedException.class, () -> {
            contactService.getTeachersForUser(3);
        });
    }
}
