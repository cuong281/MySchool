package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.SchoolClassDTO;
import com.jetbrains.grade.dto.StudentDTO;
import com.jetbrains.grade.service.SchoolClassService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/classes")
@RequiredArgsConstructor
public class SchoolClassController {

    private final SchoolClassService schoolClassService;

    @GetMapping
    public ResponseEntity<List<SchoolClassDTO>> getAll() {
        return ResponseEntity.ok(schoolClassService.getAllClasses());
    }

    @GetMapping("/{classId}/students")
    public ResponseEntity<List<StudentDTO>> getStudentsByClass(@PathVariable Integer classId) {
        return ResponseEntity.ok(schoolClassService.getStudentsByClass(classId));
    }
}
