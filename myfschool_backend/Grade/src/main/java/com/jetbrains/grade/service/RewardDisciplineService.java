package com.jetbrains.grade.service;

import com.jetbrains.grade.model.RewardDiscipline;
import com.jetbrains.grade.model.Teacher;
import com.jetbrains.grade.repository.RewardDisciplineRepository;
import com.jetbrains.grade.repository.SchoolClassRepository;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.repository.TeacherAssignmentRepository;
import com.jetbrains.grade.repository.TeacherRepository;
import com.jetbrains.grade.security.SecurityUtils;
import com.jetbrains.grade.security.TeacherAssignmentEnforcer;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RewardDisciplineService {

    private final RewardDisciplineRepository repository;
    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final SchoolClassRepository schoolClassRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final TeacherAssignmentEnforcer teacherAssignmentEnforcer;

    /**
     * Role-based search:
     * - Admin: Can view all, filter by classId, semester, type, schoolYear.
     * - Teacher: Can ONLY view records of students in classes they are homeroom teacher for.
     * - Student: Can ONLY view their own records.
     */
    public List<RewardDiscipline> search(Integer classId, Integer semester, String type, String schoolYear) {
        List<RewardDiscipline> list;

        if (SecurityUtils.isStudent()) {
            Integer currentUserId = SecurityUtils.getCurrentUserId();
            var studentOpt = studentRepository.findByUserId(currentUserId);
            if (studentOpt.isEmpty()) {
                return List.of();
            }
            list = repository.findByStudentIdOrderByIssuedDateDesc(studentOpt.get().getId());
        } else if (SecurityUtils.isTeacher() && !SecurityUtils.isAdmin()) {
            Integer currentUserId = SecurityUtils.getCurrentUserId();
            Integer teacherId = SecurityUtils.getCurrentTeacherId();
            if (teacherId == null) {
                var t = teacherRepository.findByUserId(currentUserId);
                if (t.isPresent()) teacherId = t.get().getId();
            }
            if (teacherId == null) {
                return List.of();
            }

            // Find all homeroom classes for this teacher
            Set<Integer> homeroomClassIds = new HashSet<>();
            schoolClassRepository.findByHomeroomTeacherId(teacherId).forEach(c -> homeroomClassIds.add(c.getId()));
            teacherAssignmentRepository.findByTeacherIdAndRoleType(teacherId, "HOMEROOM_TEACHER").forEach(ta -> {
                if (ta.getSchoolClass() != null) {
                    homeroomClassIds.add(ta.getSchoolClass().getId());
                }
            });

            if (homeroomClassIds.isEmpty()) {
                return List.of(); // Teacher is not a homeroom teacher
            }

            if (classId != null) {
                if (!homeroomClassIds.contains(classId)) {
                    throw new AccessDeniedException("Giao vien chi co the xem khen thuong ky luat cua lop minh chu nhiem");
                }
                list = repository.findByStudentSchoolClassIdOrderByIssuedDateDesc(classId);
            } else {
                list = repository.findByStudentSchoolClassIdInOrderByIssuedDateDesc(homeroomClassIds);
            }
        } else {
            // Admin: can see all or filter by classId
            if (classId != null) {
                list = repository.findByStudentSchoolClassIdOrderByIssuedDateDesc(classId);
            } else {
                list = repository.findAllByOrderByIssuedDateDesc();
            }
        }

        // Apply filters: semester, type, schoolYear
        return list.stream().filter(item -> {
            if (semester != null && (item.getSemester() == null || !item.getSemester().equals(semester))) {
                return false;
            }
            if (type != null && !type.trim().isEmpty() && !type.equalsIgnoreCase("all") && !type.equalsIgnoreCase("Tất cả")) {
                String groupName = item.getType() != null && item.getType().getGroupName() != null ? item.getType().getGroupName().toLowerCase() : "";
                String typeCode = item.getType() != null && item.getType().getTypeCode() != null ? item.getType().getTypeCode().toLowerCase() : "";
                String tLower = type.trim().toLowerCase();
                if (tLower.contains("khen") || tLower.contains("reward")) {
                    if (!groupName.contains("khen") && !typeCode.contains("reward")) return false;
                } else if (tLower.contains("kỷ") || tLower.contains("kỉ") || tLower.contains("luật") || tLower.contains("luat") || tLower.contains("discipline")) {
                    if (!groupName.contains("kỷ") && !groupName.contains("kỉ") && !groupName.contains("luật") && !typeCode.contains("discipline")) return false;
                } else {
                    if (!groupName.contains(tLower) && !typeCode.contains(tLower)) return false;
                }
            }
            if (schoolYear != null && !schoolYear.trim().isEmpty() && !schoolYear.equalsIgnoreCase("all") && !schoolYear.equalsIgnoreCase("Tất cả")) {
                String syName = item.getSchoolYear() != null && item.getSchoolYear().getName() != null ? item.getSchoolYear().getName() : "";
                if (!syName.equalsIgnoreCase(schoolYear.trim())) {
                    return false;
                }
            }
            return true;
        }).collect(Collectors.toList());
    }

    public List<RewardDiscipline> getByUserId(Integer userId) {
        if (SecurityUtils.isStudent()) {
            Integer currentUserId = SecurityUtils.getCurrentUserId();
            if (!userId.equals(currentUserId)) {
                throw new AccessDeniedException("Ban khong co quyen xem khen thuong ky luat cua hoc sinh khac");
            }
        }

        var studentOpt = studentRepository.findByUserId(userId);
        if (studentOpt.isEmpty()) return List.of();
        var student = studentOpt.get();

        if (SecurityUtils.isTeacher() && !SecurityUtils.isAdmin()) {
            Integer teacherId = SecurityUtils.getCurrentTeacherId();
            if (teacherId == null) {
                var t = teacherRepository.findByUserId(SecurityUtils.getCurrentUserId());
                teacherId = t.map(Teacher::getId).orElse(null);
            }
            if (student.getSchoolClass() == null || teacherId == null || !teacherAssignmentEnforcer.isHomeroomTeacher(teacherId, student.getSchoolClass().getId())) {
                throw new AccessDeniedException("Giao vien chi co the xem khen thuong ky luat cua hoc sinh lop chu nhiem");
            }
        }

        return repository.findByStudentIdOrderByIssuedDateDesc(student.getId());
    }

    public List<RewardDiscipline> getAll() {
        return search(null, null, null, null);
    }

    public List<RewardDiscipline> getByClassId(Integer classId) {
        return search(classId, null, null, null);
    }

    public RewardDiscipline save(RewardDiscipline rd) {
        if (!SecurityUtils.isAdmin()) {
            throw new AccessDeniedException("Chi quan tri vien moi co quyen them khen thuong ky luat");
        }
        if (rd.getId() == null) {
            rd.setCreatedAt(LocalDateTime.now());
        }
        rd.setUpdatedAt(LocalDateTime.now());
        return repository.save(rd);
    }
}

