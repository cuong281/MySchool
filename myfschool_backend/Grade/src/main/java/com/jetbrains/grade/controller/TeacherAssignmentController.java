package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.TeacherAssignmentDTO;
import com.jetbrains.grade.model.TeacherAssignment;
import com.jetbrains.grade.repository.TeacherAssignmentRepository;
import com.jetbrains.grade.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/teachers")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class TeacherAssignmentController {

    private final TeacherAssignmentRepository teacherAssignmentRepository;

    @GetMapping("/me/assignments")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<List<TeacherAssignmentDTO>> getMyAssignments(
            @RequestParam(required = false) Integer teacherId) {
        Integer targetTeacherId;
        if (SecurityUtils.isAdmin()) {
            if (teacherId != null) {
                targetTeacherId = teacherId;
            } else {
                return ResponseEntity.ok(teacherAssignmentRepository.findAll().stream()
                        .map(this::mapToDTO).toList());
            }
        } else {
            targetTeacherId = SecurityUtils.getCurrentTeacherId();
            if (targetTeacherId == null) {
                throw new AccessDeniedException("Khong tim thay thong tin giao vien hop le");
            }
        }

        List<TeacherAssignment> list = teacherAssignmentRepository.findByTeacherId(targetTeacherId);
        return ResponseEntity.ok(list.stream().map(this::mapToDTO).toList());
    }

    @GetMapping("/{teacherId}/assignments")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<List<TeacherAssignmentDTO>> getTeacherAssignments(@PathVariable Integer teacherId) {
        if (!SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            if (currentTeacherId == null || !currentTeacherId.equals(teacherId)) {
                throw new AccessDeniedException("Ban khong co quyen xem phan cong cua giao vien khac");
            }
        }

        List<TeacherAssignment> list = teacherAssignmentRepository.findByTeacherId(teacherId);
        return ResponseEntity.ok(list.stream().map(this::mapToDTO).toList());
    }

    private TeacherAssignmentDTO mapToDTO(TeacherAssignment ta) {
        return TeacherAssignmentDTO.builder()
                .id(ta.getId())
                .teacherId(ta.getTeacher() != null ? ta.getTeacher().getId() : null)
                .teacherName(ta.getTeacher() != null ? ta.getTeacher().getFullName() : "")
                .classId(ta.getSchoolClass() != null ? ta.getSchoolClass().getId() : null)
                .className(ta.getSchoolClass() != null ? ta.getSchoolClass().getClassName() : "")
                .subjectId(ta.getSubject() != null ? ta.getSubject().getId() : null)
                .subjectName(ta.getSubject() != null ? ta.getSubject().getSubjectName() : "")
                .subjectCode(ta.getSubject() != null ? ta.getSubject().getSubjectCode() : "")
                .roleType(ta.getRoleType())
                .build();
    }
}
