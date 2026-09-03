package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.ScheduleDayDTO;
import com.jetbrains.grade.service.ScheduleService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/schedules")
@RequiredArgsConstructor
public class ScheduleController {

    private final ScheduleService scheduleService;

    @GetMapping("/user/{userId}")
    public List<ScheduleDayDTO> getStudentSchedule(@PathVariable Integer userId) {
        return scheduleService.getStudentScheduleByUserId(userId);
    }

    @GetMapping("/class/{classId}")
    public List<ScheduleDayDTO> getByClass(@PathVariable Integer classId) {
        return scheduleService.getScheduleByClassId(classId);
    }
}
