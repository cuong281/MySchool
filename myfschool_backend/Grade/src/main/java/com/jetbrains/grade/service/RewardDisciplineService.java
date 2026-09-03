package com.jetbrains.grade.service;

import com.jetbrains.grade.model.RewardDiscipline;

import com.jetbrains.grade.repository.RewardDisciplineRepository;
import com.jetbrains.grade.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RewardDisciplineService {

    private final RewardDisciplineRepository repository;
    private final StudentRepository studentRepository;

    public List<RewardDiscipline> getByUserId(Integer userId) {
        var studentOpt = studentRepository.findByUserId(userId);
        if (studentOpt.isEmpty()) return List.of();
        return repository.findByStudentIdOrderByIssuedDateDesc(studentOpt.get().getId());
    }

    public List<RewardDiscipline> getAll() {
        return repository.findAll();
    }

    public List<RewardDiscipline> getByClassId(Integer classId) {
        return repository.findByStudentSchoolClassIdOrderByIssuedDateDesc(classId);
    }

    public RewardDiscipline save(RewardDiscipline rd) {
        if (rd.getId() == null) {
            rd.setCreatedAt(LocalDateTime.now());
        }
        rd.setUpdatedAt(LocalDateTime.now());
        return repository.save(rd);
    }
}
