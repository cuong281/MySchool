package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.AdminDashboardDTO;
import com.jetbrains.grade.dto.TeacherHomeroomDashboardDTO;
import com.jetbrains.grade.dto.TeacherSubjectStatsDTO;
import com.jetbrains.grade.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/reports")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    @GetMapping("/admin/dashboard")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminDashboardDTO> getAdminDashboard() {
        return ResponseEntity.ok(reportService.getAdminDashboard());
    }

    @GetMapping("/teacher/homeroom")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<TeacherHomeroomDashboardDTO> getTeacherHomeroomDashboard() {
        return ResponseEntity.ok(reportService.getTeacherHomeroomDashboard());
    }

    @GetMapping("/teacher/subject-stats")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<TeacherSubjectStatsDTO> getTeacherSubjectStats(
            @RequestParam Integer classId,
            @RequestParam Integer subjectId) {
        return ResponseEntity.ok(reportService.getTeacherSubjectStats(classId, subjectId));
    }
}
