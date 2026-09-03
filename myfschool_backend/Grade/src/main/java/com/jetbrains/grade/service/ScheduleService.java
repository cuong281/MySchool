package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.ScheduleDayDTO;
import com.jetbrains.grade.dto.SchedulePeriodDTO;
import com.jetbrains.grade.model.ClassSchedule;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.repository.ClassScheduleRepository;
import com.jetbrains.grade.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ScheduleService {

    private final StudentRepository studentRepository;
    private final ClassScheduleRepository classScheduleRepository;

    public List<ScheduleDayDTO> getStudentScheduleByUserId(Integer userId) {
        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        if (student.getSchoolClass() == null) {
            throw new RuntimeException("Student is not assigned to a class");
        }

        // Fetch schedules with details, ordered by DayOfWeek and SlotNumber
        List<ClassSchedule> schedules = classScheduleRepository
                .findBySchoolClassIdWithDetails(student.getSchoolClass().getId());

        // Group by DayOfWeek maintaining order
        Map<com.jetbrains.grade.model.DayOfWeekVN, List<ClassSchedule>> groupedSchedules = schedules.stream()
                .collect(Collectors.groupingBy(
                        ClassSchedule::getDayOfWeek,
                        // Use LinkedHashMap to preserve the DayOfWeek order from the query
                        java.util.LinkedHashMap::new,
                        Collectors.toList()
                ));

        // Map to DTOs
        return groupedSchedules.entrySet().stream()
                .map(entry -> ScheduleDayDTO.builder()
                        .dayOfWeek(entry.getKey())
                        .periods(entry.getValue().stream()
                                .map(schedule -> SchedulePeriodDTO.builder()
                                        .slotNumber(schedule.getTimeSlot().getSlotNumber())
                                        .startTime(schedule.getTimeSlot().getStartTime())
                                        .endTime(schedule.getTimeSlot().getEndTime())
                                        .subjectName(schedule.getSubject().getSubjectName())
                                        .teacherName(schedule.getTeacher().getFullName())
                                        .roomName(schedule.getRoomName())
                                        .build())
                                .collect(Collectors.toList()))
                        .build())
                .collect(Collectors.toList());
    }

    public List<ScheduleDayDTO> getScheduleByClassId(Integer classId) {
        // Fetch schedules with details, ordered by DayOfWeek and SlotNumber
        List<ClassSchedule> schedules = classScheduleRepository
                .findBySchoolClassIdWithDetails(classId);

        // Group by DayOfWeek maintaining order
        Map<com.jetbrains.grade.model.DayOfWeekVN, List<ClassSchedule>> groupedSchedules = schedules.stream()
                .collect(Collectors.groupingBy(
                        ClassSchedule::getDayOfWeek,
                        java.util.LinkedHashMap::new,
                        Collectors.toList()
                ));

        // Map to DTOs
        return groupedSchedules.entrySet().stream()
                .map(entry -> ScheduleDayDTO.builder()
                        .dayOfWeek(entry.getKey())
                        .periods(entry.getValue().stream()
                                .map(schedule -> SchedulePeriodDTO.builder()
                                        .slotNumber(schedule.getTimeSlot().getSlotNumber())
                                        .startTime(schedule.getTimeSlot().getStartTime())
                                        .endTime(schedule.getTimeSlot().getEndTime())
                                        .subjectName(schedule.getSubject().getSubjectName())
                                        .teacherName(schedule.getTeacher().getFullName())
                                        .roomName(schedule.getRoomName())
                                        .build())
                                .collect(Collectors.toList()))
                        .build())
                .collect(Collectors.toList());
    }
}
