package com.jetbrains.grade.service;

import com.jetbrains.grade.model.RewardDiscipline;
import com.jetbrains.grade.repository.RewardDisciplineRepository;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RewardDisciplineService {

    private final RewardDisciplineRepository repository;
    private final StudentRepository studentRepository;
    private final com.jetbrains.grade.security.TeacherAssignmentEnforcer teacherAssignmentEnforcer;

    public List<RewardDiscipline> getByUserId(Integer userId) {
        if (SecurityUtils.isStudent()) {
            Integer currentUserId = SecurityUtils.getCurrentUserId();
            if (!userId.equals(currentUserId)) {
                throw new AccessDeniedException("Ban khong co quyen xem khen thuong ky luat cua hoc sinh khac");
            }
        }

        var studentOpt = studentRepository.findByUserId(userId);
        if (studentOpt.isEmpty()) return List.of();
        return repository.findByStudentIdOrderByIssuedDateDesc(studentOpt.get().getId());
    }

    public List<RewardDiscipline> getAll() {
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Hoc sinh khong co quyen xem toan bo danh sach khen thuong ky luat");
        }
        return repository.findAll();
    }

    public List<RewardDiscipline> getByClassId(Integer classId) {
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Hoc sinh khong co quyen xem danh sach khen thuong ky luat ca lop");
        }
        if (SecurityUtils.isTeacher() && !SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            teacherAssignmentEnforcer.assertCanViewClassAttendance(currentTeacherId, classId);
        }
        return repository.findByStudentSchoolClassIdOrderByIssuedDateDesc(classId);
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
