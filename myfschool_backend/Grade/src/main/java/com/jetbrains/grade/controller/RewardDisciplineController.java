package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.RewardDisciplineCreateRequest;
import com.jetbrains.grade.dto.RewardDisciplineDTO;
import com.jetbrains.grade.model.RewardDiscipline;
import com.jetbrains.grade.service.RewardDisciplineService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

import com.jetbrains.grade.dto.PageResponse;
import com.jetbrains.grade.util.PaginationUtils;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

@RestController
@RequestMapping("/api/rewards-discipline")
@RequiredArgsConstructor
@Tag(name = "Rewards & Discipline", description = "Quản lý và tra cứu khen thưởng, kỷ luật học sinh")
public class RewardDisciplineController {

    private final RewardDisciplineService service;

    @Operation(summary = "Tìm kiếm danh sách khen thưởng / kỷ luật", description = "Admin xem toàn trường; Giáo viên xem lớp chủ nhiệm; Học sinh xem của bản thân. Hỗ trợ lọc theo classId, semester, type, schoolYear. Nếu truyền 'page', kết quả được phân trang (PageResponse); nếu không truyền, trả về List thông thường.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Tìm kiếm thành công"),
            @ApiResponse(responseCode = "401", description = "Chưa xác thực"),
            @ApiResponse(responseCode = "403", description = "Không có quyền xem dữ liệu lớp khác")
    })
    @GetMapping
    public ResponseEntity<?> getAll(
            @Parameter(description = "ID lớp học cần lọc.")
            @RequestParam(required = false) Integer classId,
            @Parameter(description = "Học kỳ (1 hoặc 2).")
            @RequestParam(required = false) Integer semester,
            @Parameter(description = "Loại ('Khen thưởng' hoặc 'Kỷ luật').")
            @RequestParam(required = false) String type,
            @Parameter(description = "Năm học (ví dụ: '2023-2024').")
            @RequestParam(required = false) String schoolYear,
            @Parameter(description = "Số trang (0-indexed). Nếu không truyền sẽ trả về toàn bộ danh sách.")
            @RequestParam(required = false) Integer page,
            @Parameter(description = "Kích thước trang (mặc định 20, tối đa 100).")
            @RequestParam(required = false) Integer size,
            @Parameter(description = "Trường sắp xếp.")
            @RequestParam(required = false) String sort,
            @Parameter(description = "Hướng sắp xếp (asc hoặc desc).")
            @RequestParam(required = false, defaultValue = "desc") String direction
    ) {
        List<RewardDisciplineDTO> results = service.search(classId, semester, type, schoolYear).stream()
                .map(this::convertToDTO)
                .toList();

        if (page == null) {
            return ResponseEntity.ok(results);
        }

        Pageable pageable = PaginationUtils.createPageable(page, size, sort, direction);
        int start = (int) Math.min(pageable.getOffset(), results.size());
        int end = Math.min(start + pageable.getPageSize(), results.size());
        List<RewardDisciplineDTO> pagedContent = results.subList(start, end);
        Page<RewardDisciplineDTO> pageResult = new PageImpl<>(pagedContent, pageable, results.size());

        return ResponseEntity.ok(PageResponse.fromPage(pageResult));
    }

    @GetMapping("/me")
    public ResponseEntity<List<RewardDisciplineDTO>> getMyRewardsDiscipline(
            @RequestParam(required = false) Integer semester,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String schoolYear
    ) {
        return ResponseEntity.ok(service.search(null, semester, type, schoolYear).stream().map(this::convertToDTO).toList());
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<RewardDisciplineDTO>> getByUserId(@PathVariable Integer userId) {
        return ResponseEntity.ok(service.getByUserId(userId).stream().map(this::convertToDTO).toList());
    }

    @GetMapping("/class/{classId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<List<RewardDisciplineDTO>> getByClassId(
            @PathVariable Integer classId,
            @RequestParam(required = false) Integer semester,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String schoolYear
    ) {
        return ResponseEntity.ok(service.search(classId, semester, type, schoolYear).stream().map(this::convertToDTO).toList());
    }

    private RewardDisciplineDTO convertToDTO(RewardDiscipline r) {
        String studentCode = r.getStudent() != null ? r.getStudent().getStudentCode() : "";
        String fullName = r.getStudent() != null ? r.getStudent().getFullName() : "N/A";
        String className = (r.getStudent() != null && r.getStudent().getSchoolClass() != null) ? r.getStudent().getSchoolClass().getClassName() : "N/A";
        Integer classId = (r.getStudent() != null && r.getStudent().getSchoolClass() != null) ? r.getStudent().getSchoolClass().getId() : null;
        Integer studentId = r.getStudent() != null ? r.getStudent().getId() : null;
        Integer userId = (r.getStudent() != null && r.getStudent().getUser() != null) ? r.getStudent().getUser().getId() : 0;
        String groupName = r.getType() != null ? r.getType().getGroupName() : "";
        String typeName = r.getType() != null ? r.getType().getTypeName() : "";
        String schoolYear = r.getSchoolYear() != null ? r.getSchoolYear().getName() : "";

        return RewardDisciplineDTO.builder()
                .id(r.getId())
                .user(RewardDisciplineDTO.UserDTO.builder()
                        .id(userId)
                        .studentId(studentId)
                        .username(fullName)
                        .className(className)
                        .classId(classId)
                        .build())
                .type(groupName)
                .typeName(typeName)
                .content(r.getContent())
                .date(r.getIssuedDate() != null ? r.getIssuedDate().toString() : "")
                .decisionNumber(r.getDecisionNumber())
                .semester(r.getSemester())
                .schoolYear(schoolYear)
                .studentCode(studentCode)
                .build();
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<RewardDisciplineDTO> create(@Valid @RequestBody RewardDisciplineCreateRequest req) {
        return ResponseEntity.ok(convertToDTO(service.create(req)));
    }
}

