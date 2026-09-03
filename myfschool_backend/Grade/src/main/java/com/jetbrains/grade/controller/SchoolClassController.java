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
}
