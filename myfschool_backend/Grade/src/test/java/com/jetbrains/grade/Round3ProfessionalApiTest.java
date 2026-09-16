package com.jetbrains.grade;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.jetbrains.grade.dto.EventCreateRequest;
import com.jetbrains.grade.dto.EventUpdateRequest;
import com.jetbrains.grade.dto.NewsCreateRequest;
import com.jetbrains.grade.dto.NewsUpdateRequest;
import com.jetbrains.grade.model.Role;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.model.Teacher;
import com.jetbrains.grade.model.User;
import com.jetbrains.grade.security.CustomUserDetails;
import com.jetbrains.grade.service.JwtService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
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

@SpringBootTest
@AutoConfigureMockMvc
public class Round3ProfessionalApiTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JwtService jwtService;

    @AfterEach
    public void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private String generateToken(int userId, String username, String roleName, Integer studentId, Integer teacherId) {
        Role role = new Role();
        role.setId(roleName.contains("ADMIN") ? 1 : (roleName.contains("TEACHER") ? 4 : 3));
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

        CustomUserDetails userDetails = new CustomUserDetails(user);
        return jwtService.generateToken(userDetails, userId, studentId, teacherId);
    }

    // =========================================================================
    // 1. SWAGGER / OPENAPI TESTS
    // =========================================================================

    @Test
    @DisplayName("Swagger OpenAPI JSON spec is publicly accessible and contains JWT Bearer security scheme")
    public void testSwaggerOpenApiJsonPubliclyAccessible() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.openapi").exists())
                .andExpect(jsonPath("$.info.title").value("MySchool Management System API"))
                .andExpect(jsonPath("$.components.securitySchemes.bearerAuth.type").value("http"))
                .andExpect(jsonPath("$.components.securitySchemes.bearerAuth.scheme").value("bearer"))
                .andExpect(jsonPath("$.components.securitySchemes.bearerAuth.bearerFormat").value("JWT"));
    }

    @Test
    @DisplayName("Swagger UI HTML page is publicly accessible without authentication")
    public void testSwaggerUiHtmlPubliclyAccessible() throws Exception {
        mockMvc.perform(get("/swagger-ui/index.html"))
                .andExpect(status().isOk());
    }

    // =========================================================================
    // 2. NEWS DTO & MASS ASSIGNMENT TESTS
    // =========================================================================

    @Test
    @DisplayName("News creation with blank title fails with 400 BAD REQUEST and validation message")
    public void testNewsValidationOnBlankTitle() throws Exception {
        String adminToken = generateToken(1, "admin", "ROLE_ADMIN", null, null);

        NewsCreateRequest invalidReq = NewsCreateRequest.builder()
                .title("") // Blank
                .content("Valid content for news article")
                .category("Tin tức")
                .build();

        mockMvc.perform(post("/api/news")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.errors.title").exists());
    }

    @Test
    @DisplayName("News creation returns 201 CREATED and prevents mass assignment of sensitive/audit fields")
    public void testNewsCreateAndMassAssignmentProtection() throws Exception {
        String adminToken = generateToken(1, "admin", "ROLE_ADMIN", null, null);

        NewsCreateRequest req = NewsCreateRequest.builder()
                .title("Thông báo học bổng học kỳ 2")
                .content("Danh sách học bổng đã được công bố trên cổng thông tin.")
                .category("Học bổng")
                .imageUrl("https://example.com/scholarship.jpg")
                .build();

        String responseJson = mockMvc.perform(post("/api/news")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.title").value("Thông báo học bổng học kỳ 2"))
                .andExpect(jsonPath("$.category").value("Học bổng"))
                .andExpect(jsonPath("$.publishedDate").exists())
                // Verify internal audit fields are NOT leaked in response DTO
                .andExpect(jsonPath("$.createdAt").doesNotExist())
                .andExpect(jsonPath("$.updatedAt").doesNotExist())
                .andReturn().getResponse().getContentAsString();

        Integer createdId = objectMapper.readTree(responseJson).get("id").asInt();

        // Update with NewsUpdateRequest
        NewsUpdateRequest updateReq = NewsUpdateRequest.builder()
                .title("Thông báo học bổng học kỳ 2 (Đã cập nhật)")
                .content("Nội dung đã được chỉnh sửa.")
                .category("Học bổng")
                .isActive(true)
                .build();

        mockMvc.perform(put("/api/news/" + createdId)
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Thông báo học bổng học kỳ 2 (Đã cập nhật)"));

        // Delete returns 200
        mockMvc.perform(delete("/api/news/" + createdId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        // Missing ID returns 404
        mockMvc.perform(get("/api/news/" + createdId))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("Querying non-existent News ID returns 404 NOT_FOUND instead of 500")
    public void testNewsNotFoundReturns404() throws Exception {
        mockMvc.perform(get("/api/news/999999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404));
    }

    // =========================================================================
    // 3. EVENT DTO & CRUD TESTS
    // =========================================================================

    @Test
    @DisplayName("Event creation returns 201 CREATED with EventDTO and complete CRUD behaves correctly")
    public void testEventCrudAndStatus201() throws Exception {
        String adminToken = generateToken(1, "admin", "ROLE_ADMIN", null, null);

        EventCreateRequest req = EventCreateRequest.builder()
                .title("Hội thao trường học 2026")
                .description("Ngày hội thể thao thường niên toàn trường.")
                .startAt(LocalDateTime.now().plusDays(5))
                .endAt(LocalDateTime.now().plusDays(7))
                .location("Sân vận động trường")
                .category("SPORTS")
                .status("Sắp tới")
                .build();

        String response = mockMvc.perform(post("/api/events")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.title").value("Hội thao trường học 2026"))
                .andExpect(jsonPath("$.color").value("#2E7D32")) // SPORTS color mapping
                .andExpect(jsonPath("$.icon").value("sports_soccer_rounded"))
                .andReturn().getResponse().getContentAsString();

        Integer eventId = objectMapper.readTree(response).get("id").asInt();

        // GET by ID returns 200
        mockMvc.perform(get("/api/events/" + eventId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(eventId))
                .andExpect(jsonPath("$.title").value("Hội thao trường học 2026"));

        // PUT update returns 200
        EventUpdateRequest updateReq = EventUpdateRequest.builder()
                .title("Hội thao trường học 2026 (Đổi ngày)")
                .description("Cập nhật thời gian thi đấu.")
                .startAt(LocalDateTime.now().plusDays(6))
                .endAt(LocalDateTime.now().plusDays(8))
                .location("Nhà thi đấu đa năng")
                .category("SPORTS")
                .status("Sắp tới")
                .build();

        mockMvc.perform(put("/api/events/" + eventId)
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Hội thao trường học 2026 (Đổi ngày)"))
                .andExpect(jsonPath("$.location").value("Nhà thi đấu đa năng"));

        // DELETE returns 200
        mockMvc.perform(delete("/api/events/" + eventId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        // Querying deleted event returns 404
        mockMvc.perform(get("/api/events/" + eventId))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("Event creation with missing title or startAt returns 400 BAD REQUEST")
    public void testEventValidationFailure() throws Exception {
        String adminToken = generateToken(1, "admin", "ROLE_ADMIN", null, null);

        EventCreateRequest req = EventCreateRequest.builder()
                .title("") // Blank title
                .startAt(null) // Null startAt
                .build();

        mockMvc.perform(post("/api/events")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.errors.title").exists())
                .andExpect(jsonPath("$.errors.startAt").exists());
    }

    // =========================================================================
    // 4. PAGINATION & BACKWARD COMPATIBILITY TESTS
    // =========================================================================

    @Test
    @DisplayName("GET /api/news without page parameter returns JSON Array (Backward Compatibility with Flutter)")
    public void testNewsPaginationBackwardCompatibility() throws Exception {
        mockMvc.perform(get("/api/news"))
                .andExpect(status().isOk())
                // Must be a JSON Array [...] for Flutter mobile app
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    @DisplayName("GET /api/news with page parameter returns PageResponse structure")
    public void testNewsPaginationOptInWithPageParam() throws Exception {
        mockMvc.perform(get("/api/news?page=0&size=5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.page").value(0))
                .andExpect(jsonPath("$.size").value(5))
                .andExpect(jsonPath("$.totalElements").isNumber())
                .andExpect(jsonPath("$.totalPages").isNumber())
                .andExpect(jsonPath("$.last").isBoolean());
    }

    @Test
    @DisplayName("GET /api/news with size=500 clamps effective size to 100 in response metadata (DoS protection)")
    public void testNewsPaginationClampingToMax100() throws Exception {
        mockMvc.perform(get("/api/news?page=0&size=500"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.size").value(100)); // Effective size must be clamped to 100
    }

    @Test
    @DisplayName("GET /api/news with negative page and size safely falls back to defaults without 500 error")
    public void testNewsPaginationSafeHandlingOfInvalidParameters() throws Exception {
        mockMvc.perform(get("/api/news?page=-1&size=-10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.page").value(0))
                .andExpect(jsonPath("$.size").value(20));
    }

    @Test
    @DisplayName("GET /api/events without page returns List array; with page returns PageResponse")
    public void testEventsPaginationBackwardCompatibilityAndOptIn() throws Exception {
        // Without page -> JSON Array
        mockMvc.perform(get("/api/events"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());

        // With page -> PageResponse
        mockMvc.perform(get("/api/events?page=0&size=5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.page").value(0))
                .andExpect(jsonPath("$.size").value(5));
    }

    @Test
    @DisplayName("GET /api/grades pagination: Admin gets PageResponse; Student is rejected with 403 (RBAC preserved)")
    public void testGradePaginationAndRbacEnforcement() throws Exception {
        String adminToken = generateToken(1, "admin", "ROLE_ADMIN", null, null);

        // As Admin: unpaged returns List
        mockMvc.perform(get("/api/grades")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());

        // As Admin: paged returns PageResponse
        mockMvc.perform(get("/api/grades?page=0&size=10")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.page").value(0))
                .andExpect(jsonPath("$.size").value(10));

        // As Student: paged request must still be rejected with 403 (Pagination does not bypass RBAC)
        String studentToken = generateToken(2, "nguyenvana", "ROLE_STUDENT", 1, null);
        mockMvc.perform(get("/api/grades?page=0&size=10")
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("GET /api/rewards-discipline supports backward-compatible unpaged List and paged PageResponse")
    public void testRewardDisciplinePagination() throws Exception {
        String adminToken = generateToken(1, "admin", "ROLE_ADMIN", null, null);

        // Without page -> List
        mockMvc.perform(get("/api/rewards-discipline")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());

        // With page -> PageResponse
        mockMvc.perform(get("/api/rewards-discipline?page=0&size=5")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.page").value(0))
                .andExpect(jsonPath("$.size").value(5));
    }

    @Test
    @DisplayName("GET /api/leave-requests supports backward-compatible unpaged List and paged PageResponse")
    public void testLeaveRequestPaginationAndRbac() throws Exception {
        String adminToken = generateToken(1, "admin", "ROLE_ADMIN", null, null);

        // Admin can view unpaged List
        mockMvc.perform(get("/api/leave-requests")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());

        // Admin can view paged PageResponse
        mockMvc.perform(get("/api/leave-requests?page=0&size=5")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.page").value(0))
                .andExpect(jsonPath("$.size").value(5));

        // Student cannot view all leave requests (403 Forbidden preserved)
        String studentToken = generateToken(2, "nguyenvana", "ROLE_STUDENT", 1, null);
        mockMvc.perform(get("/api/leave-requests?page=0&size=5")
                        .header("Authorization", "Bearer " + studentToken))
                .andExpect(status().isForbidden());
    }
}
