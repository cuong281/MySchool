package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.SubjectDTO;
import com.jetbrains.grade.repository.SubjectRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/subjects")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class SubjectController {

    private final SubjectRepository subjectRepository;

    @GetMapping
    public ResponseEntity<List<SubjectDTO>> getAll() {
        List<SubjectDTO> list = subjectRepository.findAll().stream()
                .filter(s -> Boolean.TRUE.equals(s.getIsActive()))
                .map(s -> SubjectDTO.builder()
                        .id(s.getId())
                        .subjectCode(s.getSubjectCode())
                        .subjectName(s.getSubjectName())
                        .isActive(s.getIsActive())
                        .build())
                .toList();
        return ResponseEntity.ok(list);
    }
}
