package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.ScheduleDayDTO;
import com.jetbrains.grade.service.ScheduleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/schedules")
@RequiredArgsConstructor
public class ScheduleController {

    private final ScheduleService scheduleService;

    @GetMapping("/me")
    public ResponseEntity<List<ScheduleDayDTO>> getMySchedule() {
        return ResponseEntity.ok(scheduleService.getMySchedule());
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<ScheduleDayDTO>> getStudentSchedule(@PathVariable Integer userId) {
        return ResponseEntity.ok(scheduleService.getStudentScheduleByUserId(userId));
    }

    @GetMapping("/teacher/{teacherId}")
    public ResponseEntity<List<ScheduleDayDTO>> getTeacherSchedule(@PathVariable Integer teacherId) {
        return ResponseEntity.ok(scheduleService.getTeacherSchedule(teacherId));
    }

    @GetMapping("/class/{classId}")
    public ResponseEntity<List<ScheduleDayDTO>> getByClass(@PathVariable Integer classId) {
        return ResponseEntity.ok(scheduleService.getScheduleByClassId(classId));
    }
}
