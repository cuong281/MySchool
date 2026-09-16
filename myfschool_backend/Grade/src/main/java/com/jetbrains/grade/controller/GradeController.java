package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.GradeBatchImportRequest;
import com.jetbrains.grade.dto.GradeBatchImportResponse;
import com.jetbrains.grade.dto.GradeCreateRequest;
import com.jetbrains.grade.dto.GradeDTO;
import com.jetbrains.grade.dto.GradeUpdateRequest;
import com.jetbrains.grade.model.Grade;
import com.jetbrains.grade.service.GradeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import com.jetbrains.grade.dto.PageResponse;
import com.jetbrains.grade.util.PaginationUtils;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

@RestController
@RequestMapping("/api/grades")
@RequiredArgsConstructor
@Tag(name = "Grades", description = "Quản lý điểm số, bảng điểm và nhập điểm học sinh")
public class GradeController {

    private final GradeService gradeService;

    @Operation(summary = "Lấy danh sách điểm số", description = "Admin xem toàn trường; Giáo viên xem các lớp được phân công. Nếu truyền 'page', kết quả trả về PageResponse; nếu không truyền, trả về List<GradeDTO> để tương thích ngược.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Lấy danh sách điểm số thành công"),
            @ApiResponse(responseCode = "401", description = "Chưa xác thực"),
            @ApiResponse(responseCode = "403", description = "Học sinh không có quyền xem toàn trường")
    })
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<?> getAll(
            @Parameter(description = "Số trang (0-indexed). Nếu không truyền sẽ trả về toàn bộ danh sách.")
            @RequestParam(required = false) Integer page,
            @Parameter(description = "Kích thước trang (mặc định 20, tối đa 100).")
            @RequestParam(required = false) Integer size,
            @Parameter(description = "Trường sắp xếp.")
            @RequestParam(required = false) String sort,
            @Parameter(description = "Hướng sắp xếp (asc hoặc desc).")
            @RequestParam(required = false, defaultValue = "asc") String direction
    ) {
        if (page == null) {
            return ResponseEntity.ok(gradeService.getAll().stream().map(this::mapToDTO).toList());
        }

        Pageable pageable = PaginationUtils.createPageable(page, size, sort, direction);
        Page<GradeDTO> pagedGrades = gradeService.getAll(pageable).map(this::mapToDTO);
        return ResponseEntity.ok(PageResponse.fromPage(pagedGrades));
    }

    @GetMapping("/me")
    public ResponseEntity<List<GradeDTO>> getMyGrades() {
        return ResponseEntity.ok(gradeService.getMyGrades().stream().map(this::mapToDTO).toList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Integer id) {
        Optional<Grade> result = gradeService.getById(id);
        if (result.isPresent()) {
            return ResponseEntity.ok(mapToDTO(result.get()));
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "Không tìm thấy Grade ID: " + id));
        }
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<GradeDTO>> getByUser(@PathVariable Integer userId) {
        return ResponseEntity.ok(gradeService.getByUserId(userId).stream().map(this::mapToDTO).toList());
    }

    @GetMapping("/class/{classId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<List<GradeDTO>> getByClass(@PathVariable Integer classId) {
        return ResponseEntity.ok(gradeService.getByClassId(classId).stream().map(this::mapToDTO).toList());
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<GradeDTO> create(@Valid @RequestBody GradeCreateRequest request) {
        Grade created = gradeService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(mapToDTO(created));
    }

    @PostMapping("/batch-import")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<GradeBatchImportResponse> batchImport(@Valid @RequestBody GradeBatchImportRequest request) {
        GradeBatchImportResponse response = gradeService.batchImport(request);
        if (!response.isSuccess()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<GradeDTO> update(
            @PathVariable Integer id,
            @Valid @RequestBody GradeUpdateRequest request) {
        Grade updated = gradeService.update(id, request);
        return ResponseEntity.ok(mapToDTO(updated));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<Map<String, Boolean>> delete(@PathVariable Integer id) {
        gradeService.delete(id);
        return ResponseEntity.ok(Map.of("success", true));
    }

    private GradeDTO mapToDTO(Grade g) {
        return GradeDTO.builder()
                .id(g.getId())
                .studentId(g.getStudent() != null ? g.getStudent().getId() : 0)
                .studentName(g.getStudent() != null ? g.getStudent().getFullName() : "")
                .className(g.getStudent() != null && g.getStudent().getSchoolClass() != null ? g.getStudent().getSchoolClass().getClassName() : "")
                .subjectCode(g.getSubject() != null ? g.getSubject().getSubjectCode() : "")
                .subjectName(g.getSubject() != null ? g.getSubject().getSubjectName() : "")
                .attendanceScore(g.getAttendanceScore())
                .midtermScore(g.getMidtermScore())
                .finalScore(g.getFinalScore())
                .averageScore(g.getAverageScore())
                .letterGrade(g.getLetterGrade())
                .gpa4(g.getGpa4())
                .semester(g.getSemester())
                .academicYear(g.getSchoolYear() != null ? g.getSchoolYear().getName() : "")
                .teacherName("")
                .lastModified(g.getUpdatedAt() != null ? g.getUpdatedAt().toLocalDate() : null)
                .build();
    }
}