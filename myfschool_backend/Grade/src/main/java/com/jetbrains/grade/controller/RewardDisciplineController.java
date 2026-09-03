package com.jetbrains.grade.controller;

import com.jetbrains.grade.model.RewardDiscipline;
import com.jetbrains.grade.service.RewardDisciplineService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/rewards-discipline")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class RewardDisciplineController {

    private final RewardDisciplineService service;

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<com.jetbrains.grade.dto.RewardDisciplineDTO>> getByUserId(@PathVariable Integer userId) {
        return ResponseEntity.ok(service.getByUserId(userId).stream().map(this::convertToDTO).toList());
    }

    @GetMapping
    public ResponseEntity<List<com.jetbrains.grade.dto.RewardDisciplineDTO>> getAll() {
        return ResponseEntity.ok(service.getAll().stream().map(this::convertToDTO).toList());
    }

    @GetMapping("/class/{classId}")
    public ResponseEntity<List<com.jetbrains.grade.dto.RewardDisciplineDTO>> getByClassId(@PathVariable Integer classId) {
        return ResponseEntity.ok(service.getByClassId(classId).stream().map(this::convertToDTO).toList());
    }

    private com.jetbrains.grade.dto.RewardDisciplineDTO convertToDTO(RewardDiscipline r) {
        return com.jetbrains.grade.dto.RewardDisciplineDTO.builder()
                .id(r.getId())
                .user(com.jetbrains.grade.dto.RewardDisciplineDTO.UserDTO.builder()
                        .id(r.getStudent() != null && r.getStudent().getUser() != null ? r.getStudent().getUser().getId() : 0)
                        .username(r.getStudent() != null ? r.getStudent().getFullName() : "N/A")
                        .className(r.getStudent() != null && r.getStudent().getSchoolClass() != null ? r.getStudent().getSchoolClass().getClassName() : "N/A")
                        .build())
                .type(r.getType() != null ? r.getType().getGroupName() : "")
                .content(r.getContent())
                .date(r.getIssuedDate() != null ? r.getIssuedDate().toString() : "")
                .decisionNumber(r.getDecisionNumber())
                .build();
    }

    @PostMapping
    public ResponseEntity<RewardDiscipline> create(@RequestBody RewardDiscipline rd) {
        return ResponseEntity.ok(service.save(rd));
    }
}
