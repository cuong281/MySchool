package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.SchoolClassDTO;
import com.jetbrains.grade.dto.StudentDTO;
import com.jetbrains.grade.model.SchoolClass;
import com.jetbrains.grade.repository.SchoolClassRepository;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.security.SecurityUtils;
import com.jetbrains.grade.security.TeacherAssignmentEnforcer;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.NoSuchElementException;

@Service
@RequiredArgsConstructor
public class SchoolClassService {

    private final SchoolClassRepository schoolClassRepository;
    private final StudentRepository studentRepository;
    private final TeacherAssignmentEnforcer teacherAssignmentEnforcer;

    @Transactional(readOnly = true)
    public List<SchoolClassDTO> getAllClasses() {
        return schoolClassRepository.findAll().stream()
                .map(sc -> SchoolClassDTO.builder()
                        .id(sc.getId())
                        .className(sc.getClassName())
                        .status(sc.getStatus())
                        .build())
                .toList();
    }

    @Transactional(readOnly = true)
    public List<StudentDTO> getStudentsByClass(Integer classId) {
        if (classId == null) {
            throw new IllegalArgumentException("Class ID không được để trống");
        }

        // 1. Verify class exists in database
        SchoolClass schoolClass = schoolClassRepository.findById(classId)
                .orElseThrow(() -> new NoSuchElementException("Không tìm thấy lớp học với ID: " + classId));

        // 2. Authorization enforcement:
        // Admin has full access to all classes
        if (SecurityUtils.isAdmin()) {
            return mapStudents(classId);
        }

        // Teacher: must be assigned to this class (homeroom or subject)
        if (SecurityUtils.isTeacher()) {
            Integer currentTeacherId = SecurityUtils.getCurrentTeacherId();
            if (currentTeacherId == null || !teacherAssignmentEnforcer.isAssignedToClass(currentTeacherId, classId)) {
                throw new AccessDeniedException("Giáo viên không được phân công cho lớp học này");
            }
            return mapStudents(classId);
        }

        // Student: blocked from viewing class rosters
        if (SecurityUtils.isStudent()) {
            throw new AccessDeniedException("Học sinh không có quyền truy cập danh sách học sinh của lớp học");
        }

        throw new AccessDeniedException("Bạn không có quyền truy cập danh sách học sinh của lớp học này");
    }

    private List<StudentDTO> mapStudents(Integer classId) {
        return studentRepository.findBySchoolClassIdOrderByFullNameAsc(classId).stream()
                .map(s -> StudentDTO.builder()
                        .id(s.getId())
                        .studentCode(s.getStudentCode())
                        .fullName(s.getFullName())
                        .classId(s.getSchoolClass() != null ? s.getSchoolClass().getId() : null)
                        .className(s.getSchoolClass() != null ? s.getSchoolClass().getClassName() : "")
                        .gender(s.getGender())
                        .dateOfBirth(s.getDateOfBirth())
                        .build())
                .toList();
    }
}
