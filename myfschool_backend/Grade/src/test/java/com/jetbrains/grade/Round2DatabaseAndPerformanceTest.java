package com.jetbrains.grade;

import com.jetbrains.grade.exception.ErrorResponse;
import com.jetbrains.grade.exception.GlobalExceptionHandler;
import com.jetbrains.grade.model.*;
import com.jetbrains.grade.repository.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class Round2DatabaseAndPerformanceTest {

    @Autowired
    private GradeRepository gradeRepository;

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private StudentRepository studentRepository;

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private SchoolYearRepository schoolYearRepository;

    @Autowired
    private SchoolClassRepository schoolClassRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RewardDisciplineRepository rewardDisciplineRepository;

    @Autowired
    private LeaveRequestRepository leaveRequestRepository;

    @Autowired
    private GlobalExceptionHandler globalExceptionHandler;

    @Autowired
    private CorsConfigurationSource corsConfigurationSource;

    @Value("${server.error.include-stacktrace}")
    private String includeStackTrace;

    @Value("${spring.jpa.show-sql}")
    private boolean showSql;

    // =========================================================================
    // 1. DATABASE INTEGRITY TESTS
    // =========================================================================

    @Test
    @DisplayName("Database Integrity: Reject duplicate Grade record for same (StudentID, SubjectID, SchoolYearID, Semester)")
    public void testDuplicateGradeRejection() {
        List<Grade> existingGrades = gradeRepository.findAll();
        assertFalse(existingGrades.isEmpty(), "Seed data should contain existing grades");

        Grade sample = existingGrades.get(0);

        Grade duplicate = new Grade();
        duplicate.setStudent(sample.getStudent());
        duplicate.setSubject(sample.getSubject());
        duplicate.setSchoolYear(sample.getSchoolYear());
        duplicate.setSemester(sample.getSemester());
        duplicate.setAttendanceScore(8.0);
        duplicate.setMidtermScore(8.0);
        duplicate.setFinalScore(8.0);
        duplicate.setCreatedAt(LocalDateTime.now());
        duplicate.setUpdatedAt(LocalDateTime.now());

        assertThrows(DataIntegrityViolationException.class, () -> {
            gradeRepository.saveAndFlush(duplicate);
        }, "Inserting a duplicate grade matching unique constraint must throw DataIntegrityViolationException");
    }

    @Test
    @DisplayName("Database Integrity: Reject duplicate Attendance for same (StudentID, AttendanceDate, SlotNumber)")
    public void testDuplicateAttendanceRejection() {
        Student student = studentRepository.findAll().stream().findFirst().orElseThrow();
        SchoolClass schoolClass = student.getSchoolClass() != null ? student.getSchoolClass() : schoolClassRepository.findAll().stream().findFirst().orElseThrow();
        User user = userRepository.findAll().stream().findFirst().orElseThrow();

        LocalDate testDate = LocalDate.of(2026, 12, 25);
        int slot = 99;

        // Cleanup any previous run data for this test key
        attendanceRepository.findByStudentIdAndAttendanceDateAndSlotNumber(student.getId(), testDate, slot)
                .ifPresent(existing -> attendanceRepository.delete(existing));

        Attendance first = new Attendance();
        first.setStudent(student);
        first.setSchoolClass(schoolClass);
        first.setAttendanceDate(testDate);
        first.setSlotNumber(slot);
        first.setStatus("PRESENT");
        first.setRecordedBy(user);
        first.setCreatedAt(LocalDateTime.now());
        first.setUpdatedAt(LocalDateTime.now());

        Attendance savedFirst = attendanceRepository.saveAndFlush(first);
        assertNotNull(savedFirst.getId());

        Attendance duplicate = new Attendance();
        duplicate.setStudent(student);
        duplicate.setSchoolClass(schoolClass);
        duplicate.setAttendanceDate(testDate);
        duplicate.setSlotNumber(slot);
        duplicate.setStatus("LATE");
        duplicate.setRecordedBy(user);
        duplicate.setCreatedAt(LocalDateTime.now());
        duplicate.setUpdatedAt(LocalDateTime.now());

        try {
            assertThrows(DataIntegrityViolationException.class, () -> {
                attendanceRepository.saveAndFlush(duplicate);
            }, "Inserting duplicate attendance on same date and slot must throw DataIntegrityViolationException");
        } finally {
            // Clean up test record
            try {
                attendanceRepository.delete(savedFirst);
            } catch (Exception ignored) {
            }
        }
    }

    // =========================================================================
    // 2. EXCEPTION HANDLING TESTS
    // =========================================================================

    @Test
    @DisplayName("Exception Handling: GlobalExceptionHandler translates DataIntegrityViolationException to HTTP 409 Conflict")
    public void testGlobalExceptionHandlerTranslatesDataIntegrityViolation() {
        DataIntegrityViolationException ex = new DataIntegrityViolationException("Duplicate entry '1-1-1-1' for key 'UK_Grades_Student_Subject_Year_Semester'");
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/grades");

        ResponseEntity<ErrorResponse> response = globalExceptionHandler.handleDataIntegrityViolation(ex, request);

        assertEquals(HttpStatus.CONFLICT, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(409, response.getBody().getStatus());
        assertTrue(response.getBody().getMessage().contains("Dữ liệu bị trùng lặp hoặc vi phạm ràng buộc toàn vẹn"));
        assertEquals("/api/grades", response.getBody().getPath());
    }

    // =========================================================================
    // 3. JPA PERFORMANCE & ENTITY GRAPH TESTS
    // =========================================================================

    @Test
    @DisplayName("JPA Performance: Grade EntityGraph eagerly loads relationships without LazyInitializationException")
    public void testGradeEntityGraphLoading() {
        List<Grade> list = gradeRepository.findAll();
        assertFalse(list.isEmpty());

        for (Grade grade : list) {
            assertNotNull(grade.getStudent(), "Student should be fetched");
            assertNotNull(grade.getStudent().getFullName(), "Student fields should be accessible");
            assertNotNull(grade.getSubject(), "Subject should be fetched");
            assertNotNull(grade.getSubject().getSubjectName(), "Subject name should be accessible");
            assertNotNull(grade.getSchoolYear(), "SchoolYear should be fetched");
            assertNotNull(grade.getSchoolYear().getName(), "SchoolYear name should be accessible");
            if (grade.getStudent().getSchoolClass() != null) {
                assertNotNull(grade.getStudent().getSchoolClass().getClassName(), "Nested schoolClass should be loaded without exception");
            }
        }
    }

    @Test
    @DisplayName("JPA Performance: RewardDiscipline EntityGraph eagerly loads relations")
    public void testRewardDisciplineEntityGraphLoading() {
        List<RewardDiscipline> list = rewardDisciplineRepository.findAllByOrderByIssuedDateDesc();
        for (RewardDiscipline rd : list) {
            if (rd.getStudent() != null) {
                assertNotNull(rd.getStudent().getFullName());
                if (rd.getStudent().getSchoolClass() != null) {
                    assertNotNull(rd.getStudent().getSchoolClass().getClassName());
                }
            }
            if (rd.getType() != null) {
                assertNotNull(rd.getType().getTypeName());
            }
            if (rd.getSchoolYear() != null) {
                assertNotNull(rd.getSchoolYear().getName());
            }
        }
    }

    @Test
    @DisplayName("JPA Performance: LeaveRequest EntityGraph eagerly loads relations")
    public void testLeaveRequestEntityGraphLoading() {
        List<LeaveRequest> list = leaveRequestRepository.findAll();
        for (LeaveRequest lr : list) {
            if (lr.getStudent() != null) {
                assertNotNull(lr.getStudent().getFullName());
                if (lr.getStudent().getSchoolClass() != null) {
                    assertNotNull(lr.getStudent().getSchoolClass().getClassName());
                }
            }
            if (lr.getTeacher() != null) {
                assertNotNull(lr.getTeacher().getFullName());
            }
        }
    }

    // =========================================================================
    // 4. CORS SECURITY TESTS
    // =========================================================================

    @Test
    @DisplayName("CORS Security: Explicit origins allowed and credentials enabled without wildcard origin")
    public void testCorsConfigurationRejectsWildcardWithCredentials() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader("Origin", "http://localhost:3000");

        CorsConfiguration config = corsConfigurationSource.getCorsConfiguration(request);
        assertNotNull(config, "CORS configuration should exist");

        // Credentials must be true for JWT / authorization cookies or headers
        assertTrue(Boolean.TRUE.equals(config.getAllowCredentials()), "allowCredentials should be true");

        // Must NOT contain "*" in allowed origins when credentials are true
        assertFalse(config.getAllowedOrigins().contains("*"), "Allowed origins must NOT be wildcard '*'");

        // Configured origin must be present
        assertTrue(config.getAllowedOrigins().contains("http://localhost:3000"), "Origin http://localhost:3000 should be allowed");
    }

    // =========================================================================
    // 5. PRODUCTION CONFIGURATION TESTS
    // =========================================================================

    @Test
    @DisplayName("Production Config: Stack trace is never included in error responses")
    public void testProductionErrorConfiguration() {
        assertEquals("never", includeStackTrace, "server.error.include-stacktrace must be 'never' in production");
    }

    @Test
    @DisplayName("Production Config: SQL statements are not logged to stdout")
    public void testProductionSqlLoggingDisabled() {
        assertFalse(showSql, "spring.jpa.show-sql must be false in production");
    }
}
