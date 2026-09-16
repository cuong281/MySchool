package com.jetbrains.grade;

import com.jetbrains.grade.dto.*;
import com.jetbrains.grade.exception.ErrorResponse;
import com.jetbrains.grade.exception.GlobalExceptionHandler;
import com.jetbrains.grade.model.*;
import com.jetbrains.grade.repository.SchoolClassRepository;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.security.CustomUserDetails;
import com.jetbrains.grade.security.SecurityUtils;
import com.jetbrains.grade.service.GradeService;
import com.jetbrains.grade.service.RewardDisciplineService;
import com.jetbrains.grade.service.SchoolClassService;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.MethodParameter;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.BeanPropertyBindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.time.LocalDate;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class Round1SecurityAndValidationTest {

    @Autowired
    private SchoolClassService schoolClassService;

    @Autowired
    private SchoolClassRepository schoolClassRepository;

    @Autowired
    private StudentRepository studentRepository;

    @Autowired
    private GradeService gradeService;

    @Autowired
    private RewardDisciplineService rewardDisciplineService;

    @Autowired
    private GlobalExceptionHandler globalExceptionHandler;

    @Autowired
    private com.jetbrains.grade.repository.SchoolYearRepository schoolYearRepository;

    @Autowired
    private Validator validator;

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

    // ==========================================
    // 1. CLASS AUTHORIZATION TESTS
    // ==========================================

    @Test
    public void testAdminCanAccessAnyClassStudents() {
        authenticateUser(1, "admin", "Admin", null, null);
        List<StudentDTO> students = schoolClassService.getStudentsByClass(1);
        assertNotNull(students);
        assertFalse(students.isEmpty(), "Admin should be able to view students of class 1");
    }

    @Test
    public void testAuthorizedTeacherCanAccessAssignedClassStudents() {
        // Teacher 1 is assigned to Class 1 (Homeroom and Math)
        authenticateUser(8, "teacher_han", "Teacher", null, 1);
        List<StudentDTO> students = schoolClassService.getStudentsByClass(1);
        assertNotNull(students);
        assertFalse(students.isEmpty(), "Assigned teacher should be able to view class students");
    }

    @Test
    @Transactional
    public void testUnauthorizedTeacherCannotAccessUnassignedClassStudents() {
        // Create an unassigned dummy class or use a class where teacher 1 is not assigned
        // Teacher 1 teaches class 1 and 2. Let's create an isolated class 999 if not present or find one
        SchoolClass sc = new SchoolClass();
        sc.setClassName("12Z_ISOLATED");
        sc.setStatus("ACTIVE");
        SchoolClass unassignedClass = schoolClassRepository.save(sc);

        authenticateUser(8, "teacher_han", "Teacher", null, 1);
        assertThrows(AccessDeniedException.class, () -> schoolClassService.getStudentsByClass(unassignedClass.getId()),
                "Teacher not assigned to class must receive AccessDeniedException (403)");
    }

    @Test
    public void testStudentCannotAccessClassStudents() {
        authenticateUser(2, "student_a", "Student", 1, null);
        assertThrows(AccessDeniedException.class, () -> schoolClassService.getStudentsByClass(1),
                "Student must be blocked from viewing class student rosters (403)");
    }

    @Test
    public void testNonexistentClassReturns404() {
        authenticateUser(1, "admin", "Admin", null, null);
        assertThrows(NoSuchElementException.class, () -> schoolClassService.getStudentsByClass(999999),
                "Nonexistent class must throw NoSuchElementException (404)");
    }

    // ==========================================
    // 2. BEAN VALIDATION TESTS (DTO)
    // ==========================================

    @Test
    public void testGradeCreateRequestValidation_MissingFields() {
        GradeCreateRequest req = new GradeCreateRequest();
        Set<ConstraintViolation<GradeCreateRequest>> violations = validator.validate(req);
        assertFalse(violations.isEmpty(), "Empty GradeCreateRequest must produce validation errors");
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("studentId")));
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("subjectId")));
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("schoolYearId")));
    }

    @Test
    public void testGradeCreateRequestValidation_InvalidScore() {
        GradeCreateRequest req = GradeCreateRequest.builder()
                .studentId(1)
                .subjectId(1)
                .schoolYearId(1)
                .semester(1)
                .attendanceScore(12.5) // Invalid: > 10
                .midtermScore(-1.0)   // Invalid: < 0
                .finalScore(8.0)
                .build();

        Set<ConstraintViolation<GradeCreateRequest>> violations = validator.validate(req);
        assertFalse(violations.isEmpty());
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("attendanceScore")));
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("midtermScore")));
    }

    @Test
    public void testGradeCreateRequestValidation_InvalidSemester() {
        GradeCreateRequest req = GradeCreateRequest.builder()
                .studentId(1)
                .subjectId(1)
                .schoolYearId(1)
                .semester(3) // Invalid: only 1 or 2
                .attendanceScore(8.0)
                .midtermScore(8.0)
                .finalScore(8.0)
                .build();

        Set<ConstraintViolation<GradeCreateRequest>> violations = validator.validate(req);
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("semester")));
    }

    @Test
    public void testAttendanceValidation_InvalidStatusAndNotesLength() {
        AttendanceCreateRequest req = AttendanceCreateRequest.builder()
                .studentId(1)
                .classId(1)
                .attendanceDate(LocalDate.now())
                .slotNumber(1)
                .status("UNKNOWN_STATUS") // Invalid pattern
                .note("A".repeat(300))     // Invalid length > 255
                .build();

        Set<ConstraintViolation<AttendanceCreateRequest>> violations = validator.validate(req);
        assertFalse(violations.isEmpty());
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("status")));
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("note")));
    }

    @Test
    public void testAttendanceBatchValidation_EmptyItems() {
        AttendanceBatchRequest req = AttendanceBatchRequest.builder()
                .classId(1)
                .attendanceDate(LocalDate.now())
                .slotNumber(1)
                .items(List.of()) // Invalid: @NotEmpty
                .build();

        Set<ConstraintViolation<AttendanceBatchRequest>> violations = validator.validate(req);
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("items")));
    }

    @Test
    public void testAttendanceBatchValidation_NestedItemInvalid() {
        AttendanceBatchItemDTO invalidItem = AttendanceBatchItemDTO.builder()
                .studentId(1)
                .status("INVALID_XYZ")
                .build();

        AttendanceBatchRequest req = AttendanceBatchRequest.builder()
                .classId(1)
                .attendanceDate(LocalDate.now())
                .slotNumber(1)
                .items(List.of(invalidItem))
                .build();

        Set<ConstraintViolation<AttendanceBatchRequest>> violations = validator.validate(req);
        assertTrue(violations.stream().anyMatch(v -> v.getMessage().contains("Trạng thái điểm danh không hợp lệ")));
    }

    // ==========================================
    // 3. MASS-ASSIGNMENT & SECURITY SERVICE TESTS
    // ==========================================

    @Test
    @Transactional
    public void testGradeCreateRequest_MassAssignmentProtection() {
        authenticateUser(1, "admin", "Admin", null, null);

        SchoolYear testYear = schoolYearRepository.save(
                new SchoolYear(null, "2099-2100", LocalDate.of(2099, 9, 1), LocalDate.of(2100, 5, 31), true)
        );

        GradeCreateRequest req = GradeCreateRequest.builder()
                .studentId(1)
                .subjectId(1)
                .schoolYearId(testYear.getId())
                .semester(1)
                .attendanceScore(8.0)
                .midtermScore(8.0)
                .finalScore(9.0)
                .build();

        Grade created = gradeService.create(req);
        assertNotNull(created.getId());
        assertNotNull(created.getCreatedAt());
        assertNotNull(created.getUpdatedAt());
        assertEquals(8.0, created.getAttendanceScore());
        assertEquals(8.0, created.getMidtermScore());
        assertEquals(9.0, created.getFinalScore());
    }

    @Test
    @Transactional
    public void testRewardDiscipline_IssuerAlwaysFromSecurityContext() {
        // Authenticate as Admin user 1
        authenticateUser(1, "admin", "Admin", null, null);

        RewardDisciplineCreateRequest req = RewardDisciplineCreateRequest.builder()
                .studentId(1)
                .typeId(1)
                .schoolYearId(1)
                .semester(1)
                .decisionNumber("QD-2026-TEST")
                .content("Test reward content")
                .issuedDate(LocalDate.now())
                .build();

        RewardDiscipline created = rewardDisciplineService.create(req);
        assertNotNull(created.getId());
        assertNotNull(created.getIssuedBy(), "IssuedBy must be populated by server");
        assertEquals(1, created.getIssuedBy().getId(), "IssuedBy ID must match authenticated user ID (1), ignoring any tampering");
    }

    // ==========================================
    // 4. GLOBAL EXCEPTION HANDLER TESTS
    // ==========================================

    @Test
    public void testGlobalExceptionHandler_ValidationReturns400WithErrors() throws NoSuchMethodException {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/grades");

        GradeCreateRequest target = new GradeCreateRequest();
        BeanPropertyBindingResult bindingResult = new BeanPropertyBindingResult(target, "gradeCreateRequest");
        bindingResult.addError(new FieldError("gradeCreateRequest", "studentId", "Mã học sinh không được để trống"));
        bindingResult.addError(new FieldError("gradeCreateRequest", "attendanceScore", "Điểm chuyên cần phải từ 0 đến 10"));

        MethodParameter methodParameter = new MethodParameter(
                this.getClass().getDeclaredMethod("testGlobalExceptionHandler_ValidationReturns400WithErrors"), -1
        );
        MethodArgumentNotValidException ex = new MethodArgumentNotValidException(methodParameter, bindingResult);

        ResponseEntity<ErrorResponse> response = globalExceptionHandler.handleValidationException(ex, request);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(400, response.getBody().getStatus());
        assertEquals("Bad Request", response.getBody().getError());
        assertNotNull(response.getBody().getErrors());
        assertEquals("Mã học sinh không được để trống", response.getBody().getErrors().get("studentId"));
        assertEquals("Điểm chuyên cần phải từ 0 đến 10", response.getBody().getErrors().get("attendanceScore"));
    }

    @Test
    public void testGlobalExceptionHandler_AccessDeniedReturns403() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/classes/1/students");

        AccessDeniedException ex = new AccessDeniedException("Học sinh không có quyền truy cập");
        ResponseEntity<ErrorResponse> response = globalExceptionHandler.handleAccessDeniedException(ex, request);

        assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(403, response.getBody().getStatus());
        assertEquals("Học sinh không có quyền truy cập", response.getBody().getMessage());
    }

    @Test
    public void testGlobalExceptionHandler_NotFoundReturns404() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/classes/999999/students");

        NoSuchElementException ex = new NoSuchElementException("Không tìm thấy lớp học với ID: 999999");
        ResponseEntity<ErrorResponse> response = globalExceptionHandler.handleNotFoundException(ex, request);

        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(404, response.getBody().getStatus());
        assertEquals("Không tìm thấy lớp học với ID: 999999", response.getBody().getMessage());
    }
}
