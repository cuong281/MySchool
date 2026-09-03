package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.TeacherContactDTO;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.model.TeacherAssignment;
import com.jetbrains.grade.model.User;
import com.jetbrains.grade.model.Role;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.repository.TeacherAssignmentRepository;
import com.jetbrains.grade.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ContactService {

    private final StudentRepository studentRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final UserRepository userRepository;

    public List<TeacherContactDTO> getTeachersForUser(Integer userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // If Admin, return ALL teacher assignments
        if (user.getRoles().stream().anyMatch(r -> "Admin".equalsIgnoreCase(r.getRoleName()))) {
            return teacherAssignmentRepository.findAll().stream()
                    .map(this::mapToDTO)
                    .collect(Collectors.toList());
        }

        // Original logic for students
        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Student not found"));

        if (student.getSchoolClass() == null) {
            throw new RuntimeException("Student is not assigned to a class");
        }

        List<TeacherAssignment> assignments = teacherAssignmentRepository.findBySchoolClassId(student.getSchoolClass().getId());

        return assignments.stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    private TeacherContactDTO mapToDTO(TeacherAssignment assignment) {
        return TeacherContactDTO.builder()
                .teacherId(assignment.getTeacher().getId())
                .fullName(assignment.getTeacher().getFullName())
                .email(assignment.getTeacher().getEmail())
                .phone(assignment.getTeacher().getPhoneNumber())
                .avatarUrl(assignment.getTeacher().getAvatarUrl())
                .subjectName(assignment.getSubject() != null ? assignment.getSubject().getSubjectName() : null)
                .roleType(assignment.getRoleType())
                .build();
    }
}
