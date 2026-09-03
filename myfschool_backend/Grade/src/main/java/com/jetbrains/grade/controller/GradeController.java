package com.jetbrains.grade.controller;

import com.jetbrains.grade.model.Grade;
import com.jetbrains.grade.service.GradeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
    public ResponseEntity<List<com.jetbrains.grade.dto.GradeDTO>> getAll() {
        return ResponseEntity.ok(gradeService.getAll().stream().map(this::mapToDTO).toList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Integer id) {
        Optional<Grade> result = gradeService.getById(id);
        if (result.isPresent()) {
            return ResponseEntity.ok(result.get());
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "Không tìm thấy Grade ID: " + id));
        }
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<com.jetbrains.grade.dto.GradeDTO>> getByUser(@PathVariable Integer userId) {
        return ResponseEntity.ok(gradeService.getByUserId(userId).stream().map(this::mapToDTO).toList());
    }

    @GetMapping("/class/{classId}")
    public ResponseEntity<List<com.jetbrains.grade.dto.GradeDTO>> getByClass(@PathVariable Integer classId) {
        return ResponseEntity.ok(gradeService.getByClassId(classId).stream().map(this::mapToDTO).toList());
    }

    private com.jetbrains.grade.dto.GradeDTO mapToDTO(Grade g) {
        return com.jetbrains.grade.dto.GradeDTO.builder()
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
                .teacherName("") // Can be expanded later if teacher assignments are linked
                .lastModified(g.getUpdatedAt() != null ? g.getUpdatedAt().toLocalDate() : null)
                .build();
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody Grade grade) {
        try {
            Grade created = gradeService.create(grade);
            return ResponseEntity.status(HttpStatus.CREATED).body(created);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(
            @PathVariable Integer id,
            @RequestBody Grade grade) {
        try {
            Grade updated = gradeService.update(id, grade);
            return ResponseEntity.ok(updated);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Integer id) {
        try {
            gradeService.delete(id);
            return ResponseEntity.ok(Map.of("success", true));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", e.getMessage()));
        }
    }
}