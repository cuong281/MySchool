package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.GradeBatchImportRequest;
import com.jetbrains.grade.dto.GradeBatchImportResponse;
import com.jetbrains.grade.dto.GradeDTO;
import com.jetbrains.grade.model.Grade;
import com.jetbrains.grade.service.GradeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/grades")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class GradeController {

    private final GradeService gradeService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<List<GradeDTO>> getAll() {
        return ResponseEntity.ok(gradeService.getAll().stream().map(this::mapToDTO).toList());
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
    public ResponseEntity<?> create(@RequestBody Grade grade) {
        try {
            Grade created = gradeService.create(grade);
            return ResponseEntity.status(HttpStatus.CREATED).body(mapToDTO(created));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/batch-import")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<GradeBatchImportResponse> batchImport(@RequestBody GradeBatchImportRequest request) {
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
            @RequestBody Grade grade) {
        Grade updated = gradeService.update(id, grade);
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