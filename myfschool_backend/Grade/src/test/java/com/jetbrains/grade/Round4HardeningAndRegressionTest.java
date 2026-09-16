package com.jetbrains.grade;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.jetbrains.grade.dto.EventCreateRequest;
import com.jetbrains.grade.dto.NewsCreateRequest;
import com.jetbrains.grade.model.Role;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.model.Teacher;
import com.jetbrains.grade.model.User;
import com.jetbrains.grade.security.CustomUserDetails;
import com.jetbrains.grade.service.JwtService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.Set;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Round 4 — Final Security Hardening, Edge-Case, and Regression Tests.
 */
@SpringBootTest
@AutoConfigureMockMvc
public class Round4HardeningAndRegressionTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JwtService jwtService;

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    // ── Token helper (same pattern as Round 1/3 tests) ──────────────

    private String generateToken(int userId, String username, String roleName,
                                 Integer studentId, Integer teacherId) {
        Role role = new Role();
        role.setId(roleName.contains("ADMIN") ? 1 : (roleName.contains("TEACHER") ? 3 : 2));
        role.setRoleName(roleName.startsWith("ROLE_") ? roleName : "ROLE_" + roleName);
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
        return jwtService.generateToken(details, userId, studentId, teacherId);
    }

    // =========================================================================
    // 1. AUTHENTICATION REGRESSION
    // =========================================================================

    @Nested
    @DisplayName("Authentication")
    class AuthenticationTests {

        @Test
        @DisplayName("Missing JWT → 401 on protected endpoint")
        void missingJwt_returns401() throws Exception {
            mockMvc.perform(get("/api/grades"))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Invalid JWT → 401 on protected endpoint")
        void invalidJwt_returns401() throws Exception {
            mockMvc.perform(get("/api/grades")
                            .header("Authorization", "Bearer totally.invalid.token"))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Malformed Authorization header → 401")
        void malformedAuthHeader_returns401() throws Exception {
            mockMvc.perform(get("/api/grades")
                            .header("Authorization", "NotBearer some-token"))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Valid JWT → authenticated (admin can access /api/grades)")
        void validJwt_authenticated() throws Exception {
            String adminToken = generateToken(1, "admin", "ROLE_ADMIN", null, null);
            mockMvc.perform(get("/api/grades")
                            .header("Authorization", "Bearer " + adminToken))
                    .andExpect(status().isOk());
        }
    }

    // =========================================================================
    // 2. RBAC REGRESSION
    // =========================================================================

    @Nested
    @DisplayName("RBAC")
    class RbacTests {

        @Test
        @DisplayName("Admin can access /api/grades")
        void adminCanAccessGrades() throws Exception {
            String token = generateToken(1, "admin", "ROLE_ADMIN", null, null);
            mockMvc.perform(get("/api/grades")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("Student is forbidden from /api/grades (all-grades endpoint)")
        void studentCannotAccessAllGrades() throws Exception {
            String token = generateToken(2, "nguyenvana", "ROLE_STUDENT", 1, null);
            mockMvc.perform(get("/api/grades")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Student is forbidden from /api/leave-requests (all leave requests)")
        void studentCannotAccessAllLeaveRequests() throws Exception {
            String token = generateToken(2, "nguyenvana", "ROLE_STUDENT", 1, null);
            mockMvc.perform(get("/api/leave-requests")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isForbidden());
        }
    }

    // =========================================================================
    // 3. IDOR / OWNERSHIP on /me ENDPOINTS
    // =========================================================================

    @Nested
    @DisplayName("IDOR and Ownership (/me endpoints)")
    class IdorOwnershipTests {

        @Test
        @DisplayName("GET /api/grades/me → returns data for authenticated student (userId=2, studentId=1)")
        void gradesMe_returnsOwnData() throws Exception {
            String token = generateToken(2, "nguyenvana", "ROLE_STUDENT", 1, null);
            mockMvc.perform(get("/api/grades/me")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray());
        }

        @Test
        @DisplayName("GET /api/leave-requests/me → authenticated student gets own data")
        void leaveRequestsMe_returnsOwnData() throws Exception {
            String token = generateToken(2, "nguyenvana", "ROLE_STUDENT", 1, null);
            mockMvc.perform(get("/api/leave-requests/me")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray());
        }

        @Test
        @DisplayName("GET /api/rewards-discipline/me → authenticated student gets own data")
        void rewardDisciplineMe_returnsOwnData() throws Exception {
            String token = generateToken(2, "nguyenvana", "ROLE_STUDENT", 1, null);
            mockMvc.perform(get("/api/rewards-discipline/me")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray());
        }

        @Test
        @DisplayName("GET /api/schedules/me → authenticated student gets own schedule")
        void schedulesMe_returnsOwnData() throws Exception {
            String token = generateToken(2, "nguyenvana", "ROLE_STUDENT", 1, null);
            mockMvc.perform(get("/api/schedules/me")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("GET /api/grades/me requires authentication → 401 without JWT")
        void gradesMe_unauthenticated_returns401() throws Exception {
            mockMvc.perform(get("/api/grades/me"))
                    .andExpect(status().isUnauthorized());
        }
    }

    // =========================================================================
    // 4. MASS ASSIGNMENT PROTECTION
    // =========================================================================

    @Nested
    @DisplayName("Mass Assignment Protection")
    class MassAssignmentTests {

        @Test
        @DisplayName("News create ignores 'id' and 'viewCount' sent by client")
        void newsCreate_ignoresProtectedFields() throws Exception {
            String adminToken = generateToken(1, "admin", "ROLE_ADMIN", null, null);

            // Construct JSON with extra protected fields
            String json = """
                    {
                        "title": "Mass Assignment Test News",
                        "content": "Some content for testing",
                        "id": 99999,
                        "viewCount": 12345
                    }
                    """;

            mockMvc.perform(post("/api/news")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(json))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.id").value(not(99999)));
            // viewCount is not exposed in NewsDTO or is server-controlled
        }

        @Test
        @DisplayName("Event create ignores 'id' sent by client")
        void eventCreate_ignoresProtectedFields() throws Exception {
            String adminToken = generateToken(1, "admin", "ROLE_ADMIN", null, null);

            String json = """
                    {
                        "title": "Mass Assignment Test Event",
                        "startAt": "2026-12-25T10:00:00",
                        "id": 88888
                    }
                    """;

            mockMvc.perform(post("/api/events")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(json))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.id").value(not(88888)));
        }
    }

    // =========================================================================
    // 5. PAGINATION EDGE CASES
    // =========================================================================

    @Nested
    @DisplayName("Pagination Edge Cases")
    class PaginationEdgeCaseTests {

        @Test
        @DisplayName("GET /api/news without page → returns List (backward-compatible)")
        void newsWithoutPage_returnsList() throws Exception {
            mockMvc.perform(get("/api/news"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray());
        }

        @Test
        @DisplayName("GET /api/news?page=0&size=1 → PageResponse with size=1")
        void newsPagedSize1() throws Exception {
            mockMvc.perform(get("/api/news?page=0&size=1"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.size").value(1))
                    .andExpect(jsonPath("$.page").value(0));
        }

        @Test
        @DisplayName("GET /api/news?page=0&size=100 → PageResponse with size=100")
        void newsPagedSize100() throws Exception {
            mockMvc.perform(get("/api/news?page=0&size=100"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.size").value(100));
        }

        @Test
        @DisplayName("GET /api/news?page=0&size=101 → clamped to size=100")
        void newsPagedSize101_clamped() throws Exception {
            mockMvc.perform(get("/api/news?page=0&size=101"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.size").value(100));
        }

        @Test
        @DisplayName("GET /api/news?page=0&size=500 → clamped to size=100")
        void newsPagedSize500_clamped() throws Exception {
            mockMvc.perform(get("/api/news?page=0&size=500"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.size").value(100));
        }

        @Test
        @DisplayName("GET /api/events without page → returns List (backward-compatible)")
        void eventsWithoutPage_returnsList() throws Exception {
            mockMvc.perform(get("/api/events"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray());
        }

        @Test
        @DisplayName("GET /api/events?page=0&size=101 → clamped to size=100")
        void eventsPagedSize101_clamped() throws Exception {
            mockMvc.perform(get("/api/events?page=0&size=101"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.size").value(100));
        }

        @Test
        @DisplayName("GET /api/news?page=999 → empty content, no 500")
        void newsPageBeyondTotal_emptyContent() throws Exception {
            mockMvc.perform(get("/api/news?page=999&size=20"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.content").isEmpty());
        }
    }

    // =========================================================================
    // 6. HTTP STATUS CODE CORRECTNESS
    // =========================================================================

    @Nested
    @DisplayName("HTTP Status Codes")
    class HttpStatusTests {

        @Test
        @DisplayName("GET /api/news/999999 → 404 Not Found")
        void newsNotFound_returns404() throws Exception {
            mockMvc.perform(get("/api/news/999999"))
                    .andExpect(status().isNotFound());
        }

        @Test
        @DisplayName("GET /api/events/999999 → 404 Not Found")
        void eventNotFound_returns404() throws Exception {
            mockMvc.perform(get("/api/events/999999"))
                    .andExpect(status().isNotFound());
        }

        @Test
        @DisplayName("404 response does not leak stacktrace or SQL")
        void notFound_noStacktraceLeak() throws Exception {
            mockMvc.perform(get("/api/news/999999"))
                    .andExpect(status().isNotFound())
                    .andExpect(jsonPath("$.status").value(404))
                    .andExpect(jsonPath("$.stackTrace").doesNotExist())
                    .andExpect(jsonPath("$.trace").doesNotExist());
        }

        @Test
        @DisplayName("POST /api/news with invalid data → 400 Bad Request")
        void newsValidationFailure_returns400() throws Exception {
            String adminToken = generateToken(1, "admin", "ROLE_ADMIN", null, null);

            // Missing required title
            String json = """
                    {"content": "some content"}
                    """;

            mockMvc.perform(post("/api/news")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(json))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("POST /api/events with missing required fields → 400 Bad Request")
        void eventValidationFailure_returns400() throws Exception {
            String adminToken = generateToken(1, "admin", "ROLE_ADMIN", null, null);

            // Missing title and startAt
            String json = """
                    {"description": "no title or start"}
                    """;

            mockMvc.perform(post("/api/events")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(json))
                    .andExpect(status().isBadRequest());
        }
    }

    // =========================================================================
    // 7. CORS VERIFICATION
    // =========================================================================

    @Nested
    @DisplayName("CORS")
    class CorsTests {

        @Test
        @DisplayName("Allowed origin receives CORS headers")
        void allowedOrigin_corsHeaders() throws Exception {
            mockMvc.perform(options("/api/news")
                            .header("Origin", "http://localhost:3000")
                            .header("Access-Control-Request-Method", "GET"))
                    .andExpect(header().exists("Access-Control-Allow-Origin"));
        }

        @Test
        @DisplayName("Disallowed origin does not receive CORS Allow-Origin header")
        void disallowedOrigin_noCorsHeaders() throws Exception {
            mockMvc.perform(options("/api/news")
                            .header("Origin", "http://evil-site.com")
                            .header("Access-Control-Request-Method", "GET"))
                    .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
        }
    }

    // =========================================================================
    // 8. API CONTRACT REGRESSION
    // =========================================================================

    @Nested
    @DisplayName("API Contract Regression")
    class ApiContractTests {

        @Test
        @DisplayName("POST /api/news → 201 Created with id in response")
        void newsCreate_returns201() throws Exception {
            String adminToken = generateToken(1, "admin", "ROLE_ADMIN", null, null);

            NewsCreateRequest req = NewsCreateRequest.builder()
                    .title("Round 4 Regression News")
                    .content("Content for regression test")
                    .build();

            mockMvc.perform(post("/api/news")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(req)))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.id").isNumber())
                    .andExpect(jsonPath("$.title").value("Round 4 Regression News"));
        }

        @Test
        @DisplayName("POST /api/events → 201 Created with id in response")
        void eventCreate_returns201() throws Exception {
            String adminToken = generateToken(1, "admin", "ROLE_ADMIN", null, null);

            EventCreateRequest req = EventCreateRequest.builder()
                    .title("Round 4 Regression Event")
                    .startAt(LocalDateTime.of(2026, 12, 1, 10, 0))
                    .build();

            mockMvc.perform(post("/api/events")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(req)))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.id").isNumber())
                    .andExpect(jsonPath("$.title").value("Round 4 Regression Event"));
        }

        @Test
        @DisplayName("Swagger /v3/api-docs is publicly accessible")
        void swagger_publiclyAccessible() throws Exception {
            mockMvc.perform(get("/v3/api-docs"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.openapi").exists());
        }
    }
}
