package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.*;
import com.jetbrains.grade.service.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/attendance")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class AttendanceController {

    private final AttendanceService attendanceService;

    @GetMapping("/me")
    public ResponseEntity<List<AttendanceRecordDTO>> getMyAttendance() {
        return ResponseEntity.ok(attendanceService.getMyAttendance());
    }

    @GetMapping("/me/summary")
    public ResponseEntity<AttendanceSummaryDTO> getMyAttendanceSummary() {
        return ResponseEntity.ok(attendanceService.getMyAttendanceSummary());
    }

    @GetMapping("/student/{studentId}")
    public ResponseEntity<List<AttendanceRecordDTO>> getStudentAttendance(@PathVariable Integer studentId) {
        return ResponseEntity.ok(attendanceService.getStudentAttendance(studentId));
    }

    @GetMapping("/student/{studentId}/summary")
    public ResponseEntity<AttendanceSummaryDTO> getStudentAttendanceSummary(@PathVariable Integer studentId) {
        return ResponseEntity.ok(attendanceService.getStudentAttendanceSummary(studentId));
    }

    @GetMapping("/class/{classId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<List<AttendanceRecordDTO>> getClassAttendance(
            @PathVariable Integer classId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate queryDate = date != null ? date : LocalDate.now();
        return ResponseEntity.ok(attendanceService.getClassAttendance(classId, queryDate));
    }

    @GetMapping("/class/{classId}/sheet")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<AttendanceSheetDTO> getAttendanceSheet(
            @PathVariable Integer classId,
            @RequestParam(required = false) Integer subjectId,
            @RequestParam Integer slotNumber,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate attendanceDate) {
        LocalDate date = attendanceDate != null ? attendanceDate : LocalDate.now();
        return ResponseEntity.ok(attendanceService.getAttendanceSheet(classId, subjectId, slotNumber, date));
    }

    @PostMapping("/batch")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<List<AttendanceRecordDTO>> recordBatchAttendance(@RequestBody AttendanceBatchRequest req) {
        return ResponseEntity.ok(attendanceService.recordBatchAttendance(req));
    }

    @GetMapping("/class/{classId}/history")
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<AttendanceClassHistoryDTO> getClassAttendanceHistory(
            @PathVariable Integer classId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(attendanceService.getClassAttendanceHistory(classId, startDate, endDate));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
    public ResponseEntity<?> recordAttendance(@RequestBody AttendanceCreateRequest req) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(attendanceService.recordAttendance(req));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", e.getMessage()));
        }
    }
}
