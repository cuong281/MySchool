package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.RewardDisciplineDTO;
import com.jetbrains.grade.model.RewardDiscipline;
import com.jetbrains.grade.security.SecurityUtils;
import com.jetbrains.grade.service.RewardDisciplineService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/rewards-discipline")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class RewardDisciplineController {

    private final RewardDisciplineService service;

    @GetMapping("/me")
    public ResponseEntity<List<RewardDisciplineDTO>> getMyRewardsDiscipline() {
        Integer currentUserId = SecurityUtils.getCurrentUserId();
        return ResponseEntity.ok(service.getByUserId(currentUserId).stream().map(this::convertToDTO).toList());
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<RewardDisciplineDTO>> getByUserId(@PathVariable Integer userId) {
        return ResponseEntity.ok(service.getByUserId(userId).stream().map(this::convertToDTO).toList());
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<List<RewardDisciplineDTO>> getAll() {
        return ResponseEntity.ok(service.getAll().stream().map(this::convertToDTO).toList());
    }

    @GetMapping("/class/{classId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<List<RewardDisciplineDTO>> getByClassId(@PathVariable Integer classId) {
        return ResponseEntity.ok(service.getByClassId(classId).stream().map(this::convertToDTO).toList());
    }

    private RewardDisciplineDTO convertToDTO(RewardDiscipline r) {
        return RewardDisciplineDTO.builder()
                .id(r.getId())
                .user(RewardDisciplineDTO.UserDTO.builder()
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
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<RewardDiscipline> create(@RequestBody RewardDiscipline rd) {
        return ResponseEntity.ok(service.save(rd));
    }
}
