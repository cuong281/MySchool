package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.TeacherContactDTO;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.model.Teacher;
import com.jetbrains.grade.model.TeacherAssignment;
import com.jetbrains.grade.model.User;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.repository.TeacherAssignmentRepository;
import com.jetbrains.grade.repository.TeacherRepository;
import com.jetbrains.grade.repository.UserRepository;
import com.jetbrains.grade.security.SecurityUtils;
import com.jetbrains.grade.security.TeacherAssignmentEnforcer;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ContactService {

    private final StudentRepository studentRepository;
    private final TeacherRepository teacherRepository;
    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final UserRepository userRepository;
    private final TeacherAssignmentEnforcer teacherAssignmentEnforcer;

    public List<TeacherContactDTO> getMyTeachers() {
        if (SecurityUtils.isStudent()) {
            Integer currentUserId = SecurityUtils.getCurrentUserId();
            return getTeachersForUser(currentUserId);
        }

        if (SecurityUtils.isTeacher() || SecurityUtils.isAdmin()) {
            return getAllTeachersForStaff();
        }

        Integer currentUserId = SecurityUtils.getCurrentUserId();
        return getTeachersForUser(currentUserId);
    }

    public List<TeacherContactDTO> getTeachersForUser(Integer userId) {
        // Enforce ownership: student can only query their own contacts
        if (SecurityUtils.isStudent()) {
            Integer currentUserId = SecurityUtils.getCurrentUserId();
            if (!userId.equals(currentUserId)) {
                throw new AccessDeniedException("Ban khong co quyen xem danh ba lien lac cua hoc sinh khac");
            }
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found with ID: " + userId));

        // If Admin, return all teachers for staff
        if (SecurityUtils.isAdmin()) {
            return getAllTeachersForStaff();
        }

        // Student contact query
        Student student = studentRepository.findByUserId(userId)
                .orElseThrow(() -> new NoSuchElementException("Student not found for User ID: " + userId));

        // If caller is teacher, ensure teacher has scope over this student's class
        if (SecurityUtils.isTeacher() && !SecurityUtils.isAdmin()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            teacherAssignmentEnforcer.assertCanViewStudentData(currentTeacherId, student);
        }

        if (student.getSchoolClass() == null) {
            throw new IllegalArgumentException("Student is not assigned to a class");
        }

        List<TeacherAssignment> assignments = teacherAssignmentRepository.findBySchoolClassId(student.getSchoolClass().getId());

        // Sort: HOMEROOM_TEACHER first, then by Teacher FullName
        assignments.sort((a, b) -> {
            boolean aHome = "HOMEROOM_TEACHER".equals(a.getRoleType());
            boolean bHome = "HOMEROOM_TEACHER".equals(b.getRoleType());
            if (aHome && !bHome) return -1;
            if (!aHome && bHome) return 1;
            return a.getTeacher().getFullName().compareToIgnoreCase(b.getTeacher().getFullName());
        });

        boolean isCallerStudent = SecurityUtils.isStudent();

        return assignments.stream()
                .map(a -> mapToDTO(a, isCallerStudent))
                .collect(Collectors.toList());
    }

    public List<TeacherContactDTO> getAllTeachersForStaff() {
        List<Teacher> teachers = teacherRepository.findAll();
        List<TeacherAssignment> allAssignments = teacherAssignmentRepository.findAll();

        Map<Integer, List<TeacherAssignment>> assignmentsByTeacher = allAssignments.stream()
                .filter(a -> a.getTeacher() != null)
                .collect(Collectors.groupingBy(a -> a.getTeacher().getId()));

        return teachers.stream().map(teacher -> {
            List<TeacherAssignment> tAssignments = assignmentsByTeacher.getOrDefault(teacher.getId(), Collections.emptyList());
            String subjects = tAssignments.stream()
                    .map(a -> a.getSubject() != null ? a.getSubject().getSubjectName() : "")
                    .filter(s -> !s.isEmpty())
                    .distinct()
                    .collect(Collectors.joining(", "));

            boolean isHomeroom = tAssignments.stream().anyMatch(a -> "HOMEROOM_TEACHER".equals(a.getRoleType()));
            String roleType = isHomeroom ? "HOMEROOM_TEACHER" : "SUBJECT_TEACHER";

            return TeacherContactDTO.builder()
                    .teacherId(teacher.getId())
                    .userId(teacher.getUser() != null ? teacher.getUser().getId() : null)
                    .fullName(teacher.getFullName())
                    .email(teacher.getEmail())
                    .phone(teacher.getPhoneNumber()) // Staff & Admin can view phone
                    .avatarUrl(teacher.getAvatarUrl())
                    .subjectName(subjects.isEmpty() ? null : subjects)
                    .roleType(roleType)
                    .isHomeroom(isHomeroom)
                    .isPhonePublic(Boolean.TRUE.equals(teacher.getIsPhonePublic()))
                    .status(teacher.getStatus())
                    .build();
        }).collect(Collectors.toList());
    }

    public boolean updateMyPhonePrivacy(boolean isPhonePublic) {
        Integer resolvedTeacherId = SecurityUtils.getCurrentTeacherId();
        if (resolvedTeacherId == null) {
            Integer currentUserId = SecurityUtils.getCurrentUserId();
            Teacher currentTeacher = teacherRepository.findByUserId(currentUserId)
                    .orElseThrow(() -> new AccessDeniedException("Chi giao vien moi co the cau hinh quyen rieng tu SĐT"));
            resolvedTeacherId = currentTeacher.getId();
        }
        final Integer targetTeacherId = resolvedTeacherId;
        Teacher teacher = teacherRepository.findById(targetTeacherId)
                .orElseThrow(() -> new NoSuchElementException("Teacher not found with ID: " + targetTeacherId));
        teacher.setIsPhonePublic(isPhonePublic);
        teacherRepository.save(teacher);
        return Boolean.TRUE.equals(teacher.getIsPhonePublic());
    }

    private TeacherContactDTO mapToDTO(TeacherAssignment assignment, boolean maskPhoneIfNotPublic) {
        Teacher teacher = assignment.getTeacher();
        boolean isPublic = Boolean.TRUE.equals(teacher.getIsPhonePublic());
        String phone = (maskPhoneIfNotPublic && !isPublic) ? null : teacher.getPhoneNumber();
        boolean isHomeroom = "HOMEROOM_TEACHER".equals(assignment.getRoleType());

        return TeacherContactDTO.builder()
                .teacherId(teacher.getId())
                .userId(teacher.getUser() != null ? teacher.getUser().getId() : null)
                .fullName(teacher.getFullName())
                .email(teacher.getEmail())
                .phone(phone)
                .avatarUrl(teacher.getAvatarUrl())
                .subjectName(assignment.getSubject() != null ? assignment.getSubject().getSubjectName() : null)
                .roleType(assignment.getRoleType())
                .isHomeroom(isHomeroom)
                .isPhonePublic(isPublic)
                .status(teacher.getStatus())
                .build();
    }
}
