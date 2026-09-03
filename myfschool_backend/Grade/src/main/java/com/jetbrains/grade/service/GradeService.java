package com.jetbrains.grade.service;

import com.jetbrains.grade.model.Grade;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.repository.GradeRepository;
import com.jetbrains.grade.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class GradeService {

    private final GradeRepository gradeRepository;
    private final StudentRepository studentRepository;

    public List<Grade> getAll() {
        return gradeRepository.findAll();
    }

    public Optional<Grade> getById(Integer id) {
        return gradeRepository.findById(id);
    }

    public List<Grade> getByUserId(Integer userId) {
        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Student not found"));
        return gradeRepository.findByStudentId(student.getId());
    }

    public List<Grade> getByClassId(Integer classId) {
        return gradeRepository.findByStudentSchoolClassId(classId);
    }

    public Grade create(Grade grade) {
        if (grade.getStudent() == null || grade.getSubject() == null || grade.getSchoolYear() == null) {
            throw new IllegalArgumentException("Khong du thong tin: Student, Subject, SchoolYear");
        }
        if (gradeRepository.existsByStudentIdAndSubjectIdAndSchoolYearIdAndSemester(
                grade.getStudent().getId(), grade.getSubject().getId(), grade.getSchoolYear().getId(), grade.getSemester())) {
            throw new IllegalArgumentException("Hoc sinh da co diem mon nay trong hoc ky va nam hoc nay");
        }
        
        grade.setId(null);
        grade.setCreatedAt(LocalDateTime.now());
        grade.setUpdatedAt(LocalDateTime.now());
        Grade saved = gradeRepository.save(grade);
        
        return gradeRepository.findById(saved.getId()).orElse(saved);
    }

    public Grade update(Integer id, Grade updatedData) {
        Grade existing = gradeRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay Grade ID: " + id));

        existing.setAttendanceScore(updatedData.getAttendanceScore());
        existing.setMidtermScore(updatedData.getMidtermScore());
        existing.setFinalScore(updatedData.getFinalScore());
        existing.setUpdatedAt(LocalDateTime.now());

        Grade saved = gradeRepository.save(existing);
        return gradeRepository.findById(saved.getId()).orElse(saved);
    }

    public void delete(Integer id) {
        if (!gradeRepository.existsById(id)) {
            throw new IllegalArgumentException("Khong tim thay Grade ID: " + id);
        }
        gradeRepository.deleteById(id);
    }
}