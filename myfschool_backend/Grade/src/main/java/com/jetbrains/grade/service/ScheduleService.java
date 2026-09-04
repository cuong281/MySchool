package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.ScheduleDayDTO;
import com.jetbrains.grade.dto.SchedulePeriodDTO;
import com.jetbrains.grade.model.ClassSchedule;
import com.jetbrains.grade.model.DayOfWeekVN;
import com.jetbrains.grade.model.SchoolClass;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.model.Teacher;
import com.jetbrains.grade.repository.ClassScheduleRepository;
import com.jetbrains.grade.repository.SchoolClassRepository;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.repository.TeacherRepository;
import com.jetbrains.grade.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ScheduleService {

    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final SchoolClassRepository schoolClassRepository;
    private final ClassScheduleRepository classScheduleRepository;

    public List<ScheduleDayDTO> getStudentScheduleByUserId(Integer userId) {
        // Enforce ownership: student can only access their own schedule
        if (SecurityUtils.isStudent()) {
            Integer currentUserId = SecurityUtils.getCurrentUserId();
            if (!userId.equals(currentUserId)) {
                throw new AccessDeniedException("Ban khong co quyen xem thoi khoa bieu cua hoc sinh khac");
            }
        }

        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay thong tin hoc sinh cho User ID: " + userId));

        if (student.getSchoolClass() == null) {
            throw new IllegalArgumentException("Hoc sinh chua duoc phan vao lop hoc");
        }

        return getScheduleByClassIdInternal(student.getSchoolClass().getId());
    }

    public List<ScheduleDayDTO> getMySchedule() {
        if (SecurityUtils.isStudent()) {
            Integer currentUserId = SecurityUtils.getCurrentUserId();
            return getStudentScheduleByUserId(currentUserId);
        }

        if (SecurityUtils.isTeacher()) {
            Integer teacherId = SecurityUtils.getCurrentTeacherId();
            if (teacherId == null) {
                Integer currentUserId = SecurityUtils.getCurrentUserId();
                Teacher teacher = teacherRepository.findByUserId(currentUserId)
                        .orElseThrow(() -> new IllegalArgumentException("Khong tim thay thong tin giao vien"));
                teacherId = teacher.getId();
            }
            return getTeacherScheduleInternal(teacherId);
        }

        if (SecurityUtils.isAdmin()) {
            // Admin default: return schedule of the first active class if available
            List<SchoolClass> classes = schoolClassRepository.findAll();
            if (!classes.isEmpty()) {
                return getScheduleByClassIdInternal(classes.get(0).getId());
            }
            return Collections.emptyList();
        }

        return Collections.emptyList();
    }

    public List<ScheduleDayDTO> getTeacherSchedule(Integer teacherId) {
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Hoc sinh khong co quyen xem lich giang day cua giao vien");
        }

        if (SecurityUtils.isTeacher()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            if (currentTeacherId == null) {
                Integer currentUserId = SecurityUtils.getCurrentUserId();
                Teacher teacher = teacherRepository.findByUserId(currentUserId)
                        .orElseThrow(() -> new IllegalArgumentException("Khong tim thay thong tin giao vien"));
                currentTeacherId = teacher.getId();
            }
            if (!teacherId.equals(currentTeacherId)) {
                throw new AccessDeniedException("Giao vien chi co the xem lich giang day cua chinh minh");
            }
        }

        return getTeacherScheduleInternal(teacherId);
    }

    public List<ScheduleDayDTO> getScheduleByClassId(Integer classId) {
        // If caller is student, verify they belong to this class
        if (SecurityUtils.isStudent()) {
            Integer currentUserId = SecurityUtils.getCurrentUserId();
            Student student = studentRepository.findByUserId(currentUserId)
                    .orElseThrow(() -> new IllegalArgumentException("Khong tim thay thong tin hoc sinh"));

            if (student.getSchoolClass() == null || !student.getSchoolClass().getId().equals(classId)) {
                throw new AccessDeniedException("Ban khong thuoc lop hoc nay nen khong the xem thoi khoa bieu");
            }
        }

        // Teachers and Admins can view any class schedule
        return getScheduleByClassIdInternal(classId);
    }

    private List<ScheduleDayDTO> getScheduleByClassIdInternal(Integer classId) {
        List<ClassSchedule> schedules = classScheduleRepository.findBySchoolClassIdWithDetails(classId);
        return mapToScheduleDayDTOs(schedules);
    }

    private List<ScheduleDayDTO> getTeacherScheduleInternal(Integer teacherId) {
        List<ClassSchedule> schedules = classScheduleRepository.findByTeacherIdWithDetails(teacherId);
        return mapToScheduleDayDTOs(schedules);
    }

    private List<ScheduleDayDTO> mapToScheduleDayDTOs(List<ClassSchedule> schedules) {
        Map<DayOfWeekVN, List<ClassSchedule>> groupedSchedules = schedules.stream()
                .collect(Collectors.groupingBy(
                        ClassSchedule::getDayOfWeek,
                        LinkedHashMap::new,
                        Collectors.toList()
                ));

        return groupedSchedules.entrySet().stream()
                .map(entry -> ScheduleDayDTO.builder()
                        .dayOfWeek(entry.getKey())
                        .periods(entry.getValue().stream()
                                .map(schedule -> SchedulePeriodDTO.builder()
                                        .slotNumber(schedule.getTimeSlot().getSlotNumber())
                                        .startTime(schedule.getTimeSlot().getStartTime())
                                        .endTime(schedule.getTimeSlot().getEndTime())
                                        .subjectName(schedule.getSubject().getSubjectName())
                                        .teacherName(schedule.getTeacher() != null ? schedule.getTeacher().getFullName() : "")
                                        .roomName(schedule.getRoomName())
                                        .classId(schedule.getSchoolClass() != null ? schedule.getSchoolClass().getId() : null)
                                        .className(schedule.getSchoolClass() != null ? schedule.getSchoolClass().getClassName() : null)
                                        .build())
                                .collect(Collectors.toList()))
                        .build())
                .collect(Collectors.toList());
    }
}
