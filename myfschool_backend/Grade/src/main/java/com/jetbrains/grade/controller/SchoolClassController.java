package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.SchoolClassDTO;
import com.jetbrains.grade.repository.SchoolClassRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/classes")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class SchoolClassController {

    private final SchoolClassRepository schoolClassRepository;
    private final com.jetbrains.grade.repository.StudentRepository studentRepository;

    @GetMapping
    public ResponseEntity<List<SchoolClassDTO>> getAll() {
        List<SchoolClassDTO> dtos = schoolClassRepository.findAll().stream()
                .map(sc -> SchoolClassDTO.builder()
                        .id(sc.getId())
                        .className(sc.getClassName())
                        .status(sc.getStatus())
                        .build())
                .toList();
        return ResponseEntity.ok(dtos);
    }

    @GetMapping("/{classId}/students")
    public ResponseEntity<List<com.jetbrains.grade.dto.StudentDTO>> getStudentsByClass(@PathVariable Integer classId) {
        List<com.jetbrains.grade.dto.StudentDTO> dtos = studentRepository.findBySchoolClassIdOrderByFullNameAsc(classId).stream()
                .map(s -> com.jetbrains.grade.dto.StudentDTO.builder()
                        .id(s.getId())
                        .studentCode(s.getStudentCode())
                        .fullName(s.getFullName())
                        .classId(s.getSchoolClass() != null ? s.getSchoolClass().getId() : null)
                        .className(s.getSchoolClass() != null ? s.getSchoolClass().getClassName() : "")
                        .gender(s.getGender())
                        .dateOfBirth(s.getDateOfBirth())
                        .build())
                .toList();
        return ResponseEntity.ok(dtos);
    }
}
