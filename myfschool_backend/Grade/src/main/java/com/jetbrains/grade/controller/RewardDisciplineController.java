package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.RewardDisciplineDTO;
import com.jetbrains.grade.model.RewardDiscipline;
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

    @GetMapping
    public ResponseEntity<List<RewardDisciplineDTO>> getAll(
            @RequestParam(required = false) Integer classId,
            @RequestParam(required = false) Integer semester,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String schoolYear
    ) {
        return ResponseEntity.ok(service.search(classId, semester, type, schoolYear).stream().map(this::convertToDTO).toList());
    }

    @GetMapping("/me")
    public ResponseEntity<List<RewardDisciplineDTO>> getMyRewardsDiscipline(
            @RequestParam(required = false) Integer semester,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String schoolYear
    ) {
        return ResponseEntity.ok(service.search(null, semester, type, schoolYear).stream().map(this::convertToDTO).toList());
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<RewardDisciplineDTO>> getByUserId(@PathVariable Integer userId) {
        return ResponseEntity.ok(service.getByUserId(userId).stream().map(this::convertToDTO).toList());
    }

    @GetMapping("/class/{classId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<List<RewardDisciplineDTO>> getByClassId(
            @PathVariable Integer classId,
            @RequestParam(required = false) Integer semester,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String schoolYear
    ) {
        return ResponseEntity.ok(service.search(classId, semester, type, schoolYear).stream().map(this::convertToDTO).toList());
    }

    private RewardDisciplineDTO convertToDTO(RewardDiscipline r) {
        String studentCode = r.getStudent() != null ? r.getStudent().getStudentCode() : "";
        String fullName = r.getStudent() != null ? r.getStudent().getFullName() : "N/A";
        String className = (r.getStudent() != null && r.getStudent().getSchoolClass() != null) ? r.getStudent().getSchoolClass().getClassName() : "N/A";
        Integer classId = (r.getStudent() != null && r.getStudent().getSchoolClass() != null) ? r.getStudent().getSchoolClass().getId() : null;
        Integer studentId = r.getStudent() != null ? r.getStudent().getId() : null;
        Integer userId = (r.getStudent() != null && r.getStudent().getUser() != null) ? r.getStudent().getUser().getId() : 0;
        String groupName = r.getType() != null ? r.getType().getGroupName() : "";
        String typeName = r.getType() != null ? r.getType().getTypeName() : "";
        String schoolYear = r.getSchoolYear() != null ? r.getSchoolYear().getName() : "";

        return RewardDisciplineDTO.builder()
                .id(r.getId())
                .user(RewardDisciplineDTO.UserDTO.builder()
                        .id(userId)
                        .studentId(studentId)
                        .username(fullName)
                        .className(className)
                        .classId(classId)
                        .build())
                .type(groupName)
                .typeName(typeName)
                .content(r.getContent())
                .date(r.getIssuedDate() != null ? r.getIssuedDate().toString() : "")
                .decisionNumber(r.getDecisionNumber())
                .semester(r.getSemester())
                .schoolYear(schoolYear)
                .studentCode(studentCode)
                .build();
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<RewardDiscipline> create(@RequestBody RewardDiscipline rd) {
        return ResponseEntity.ok(service.save(rd));
    }
}

