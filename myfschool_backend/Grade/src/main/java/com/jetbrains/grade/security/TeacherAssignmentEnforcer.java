package com.jetbrains.grade.security;

import com.jetbrains.grade.model.Grade;
import com.jetbrains.grade.model.LeaveRequest;
import com.jetbrains.grade.model.Student;
import com.jetbrains.grade.repository.SchoolClassRepository;
import com.jetbrains.grade.repository.StudentRepository;
import com.jetbrains.grade.repository.TeacherAssignmentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class TeacherAssignmentEnforcer {

    private final TeacherAssignmentRepository teacherAssignmentRepository;
    private final SchoolClassRepository schoolClassRepository;
    private final StudentRepository studentRepository;

    public boolean isHomeroomTeacher(Integer teacherId, Integer classId) {
        if (teacherId == null || classId == null) return false;
        return schoolClassRepository.existsByIdAndHomeroomTeacherId(classId, teacherId)
                || teacherAssignmentRepository.existsByTeacherIdAndSchoolClassIdAndRoleType(teacherId, classId, "HOMEROOM_TEACHER");
    }

    public boolean isSubjectTeacher(Integer teacherId, Integer classId, Integer subjectId) {
        if (teacherId == null || classId == null || subjectId == null) return false;
        return teacherAssignmentRepository.existsByTeacherIdAndSchoolClassIdAndSubjectId(teacherId, classId, subjectId);
    }

    public boolean isAssignedToClass(Integer teacherId, Integer classId) {
        if (teacherId == null || classId == null) return false;
        return isHomeroomTeacher(teacherId, classId)
                || teacherAssignmentRepository.existsByTeacherIdAndSchoolClassId(teacherId, classId);
    }

    public boolean isHomeroomTeacherOfStudent(Integer teacherId, Integer studentId) {
        if (teacherId == null || studentId == null) return false;
        Student student = studentRepository.findById(studentId).orElse(null);
        if (student == null || student.getSchoolClass() == null) return false;
        return isHomeroomTeacher(teacherId, student.getSchoolClass().getId());
    }

    /**
     * Subject Teacher can manage (create/update/delete) grades ONLY for assigned (Class, Subject).
     */
    public void assertCanManageGrade(Integer teacherId, Integer studentId, Integer subjectId) {
        if (SecurityUtils.isAdmin()) return;
        if (teacherId == null) {
            throw new AccessDeniedException("Khong tim thay thong tin giao vien hop le");
        }
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay thong tin hoc sinh"));
        if (student.getSchoolClass() == null) {
            throw new AccessDeniedException("Hoc sinh chua duoc phan lop");
        }
        Integer classId = student.getSchoolClass().getId();
        if (!isSubjectTeacher(teacherId, classId, subjectId)) {
            throw new AccessDeniedException("Giao vien khong duoc phan cong giang day mon hoc nay cho lop cua hoc sinh");
        }
    }

    /**
     * Homeroom teacher can view all grades of their class.
     * Subject teacher can view grades of their assigned subjects.
     */
    public void assertCanViewGrade(Integer teacherId, Grade grade) {
        if (SecurityUtils.isAdmin()) return;
        if (teacherId == null) {
            throw new AccessDeniedException("Khong tim thay thong tin giao vien hop le");
        }
        if (grade == null || grade.getStudent() == null || grade.getStudent().getSchoolClass() == null) {
            throw new AccessDeniedException("Du lieu diem khong hop le");
        }
        Integer classId = grade.getStudent().getSchoolClass().getId();
        Integer subjectId = grade.getSubject() != null ? grade.getSubject().getId() : null;

        // Homeroom teacher of student's class has read-only access to all grades
        if (isHomeroomTeacher(teacherId, classId)) {
            return;
        }

        // Subject teacher can view grades of assigned subject in this class
        if (subjectId != null && isSubjectTeacher(teacherId, classId, subjectId)) {
            return;
        }

        throw new AccessDeniedException("Giao vien khong co quyen xem diem cua mon/lop nay");
    }

    /**
     * Homeroom Teacher can record daily/general attendance (or any slot) for their class.
     * Subject Teacher can record attendance for their assigned (Class, Subject).
     */
    public void assertCanManageAttendance(Integer teacherId, Integer classId, Integer subjectId) {
        if (SecurityUtils.isAdmin()) return;
        if (teacherId == null) {
            throw new AccessDeniedException("Khong tim thay thong tin giao vien hop le");
        }

        if (isHomeroomTeacher(teacherId, classId)) {
            return; // Homeroom teacher has full attendance management for their class
        }

        if (subjectId != null && isSubjectTeacher(teacherId, classId, subjectId)) {
            return; // Subject teacher can record attendance for their subject session
        }

        throw new AccessDeniedException("Giao vien khong duoc phan cong diem danh cho lop/mon hoc nay");
    }

    public void assertCanViewClassAttendance(Integer teacherId, Integer classId) {
        if (SecurityUtils.isAdmin()) return;
        if (teacherId == null) {
            throw new AccessDeniedException("Khong tim thay thong tin giao vien hop le");
        }
        if (!isAssignedToClass(teacherId, classId)) {
            throw new AccessDeniedException("Giao vien khong duoc phan cong cho lop hoc nay");
        }
    }

    public void assertCanViewStudentData(Integer teacherId, Student student) {
        if (SecurityUtils.isAdmin()) return;
        if (teacherId == null) {
            throw new AccessDeniedException("Khong tim thay thong tin giao vien hop le");
        }
        if (student == null || student.getSchoolClass() == null) {
            throw new AccessDeniedException("Khong tim thay thong tin lop cua hoc sinh");
        }
        if (!isAssignedToClass(teacherId, student.getSchoolClass().getId())) {
            throw new AccessDeniedException("Giao vien khong co quyen xem thong tin hoc sinh cua lop nay");
        }
    }

    /**
     * Only Homeroom Teacher (or Admin) can process (approve/reject) Leave Requests.
     */
    public void assertCanProcessLeaveRequest(Integer teacherId, LeaveRequest request) {
        if (SecurityUtils.isAdmin()) return;
        if (teacherId == null) {
            throw new AccessDeniedException("Khong tim thay thong tin giao vien hop le");
        }
        if (request == null || request.getStudent() == null) {
            throw new AccessDeniedException("Don xin phep khong hop le");
        }
        if (!isHomeroomTeacherOfStudent(teacherId, request.getStudent().getId())) {
            throw new AccessDeniedException("Chi giao vien chu nhiem cua lop hoc sinh moi co quyen duyet don xin phep");
        }
    }
}
