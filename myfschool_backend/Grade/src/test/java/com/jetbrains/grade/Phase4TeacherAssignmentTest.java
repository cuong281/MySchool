package com.jetbrains.grade;

import com.jetbrains.grade.dto.AttendanceCreateRequest;
import com.jetbrains.grade.dto.AttendanceRecordDTO;
import com.jetbrains.grade.dto.TeacherAssignmentDTO;
import com.jetbrains.grade.model.*;
import com.jetbrains.grade.repository.*;
import com.jetbrains.grade.security.CustomUserDetails;
import com.jetbrains.grade.security.SecurityUtils;
import com.jetbrains.grade.service.AttendanceService;
import com.jetbrains.grade.service.GradeService;
import com.jetbrains.grade.service.LeaveRequestService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class Phase4TeacherAssignmentTest {

    @Autowired
    private GradeService gradeService;

    @Autowired
    private AttendanceService attendanceService;

    @Autowired
    private LeaveRequestService leaveRequestService;

    @Autowired
    private TeacherAssignmentRepository teacherAssignmentRepository;

    @Autowired
    private StudentRepository studentRepository;

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private SchoolYearRepository schoolYearRepository;

    @Autowired
    private GradeRepository gradeRepository;

    @Autowired
    private LeaveRequestRepository leaveRequestRepository;

    @AfterEach
    public void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private void authenticateUser(int userId, String username, String roleName, Integer studentId, Integer teacherId) {
        Role role = new Role();
        role.setId(roleName.equals("Admin") ? 1 : (roleName.equals("Teacher") ? 4 : 3));
        role.setRoleName(roleName);
        role.setIsActive(true);

        User user = new User();
        user.setId(userId);
        user.setUsername(username);
        user.setPasswordHash("hashed_dummy");
        user.setPhoneNumber("090" + userId + "000000");
        user.setIsActive(true);
        user.setRoles(Set.of(role));

        if (studentId != null) {
            Student student = new Student();
            student.setId(studentId);
            student.setUser(user);
            user.setStudent(student);
        }

        if (teacherId != null) {
            Teacher teacher = new Teacher();
            teacher.setId(teacherId);
            teacher.setUser(user);
            user.setTeacher(teacher);
        }

        CustomUserDetails userDetails = new CustomUserDetails(user);
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                userDetails, null, userDetails.getAuthorities()
        );
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    public void testTeacherAssignmentsDiscovery() {
        // Teacher 1 (teacherId = 1, Nguyen Ngoc Han)
        List<TeacherAssignment> assignmentsT1 = teacherAssignmentRepository.findByTeacherId(1);
        assertFalse(assignmentsT1.isEmpty(), "Teacher 1 should have assignments");

        // Teacher 1 is Homeroom for Class 1
        boolean isHomeroom10A1 = assignmentsT1.stream().anyMatch(
                a -> a.getSchoolClass().getId().equals(1) && "HOMEROOM_TEACHER".equals(a.getRoleType()));
        assertTrue(isHomeroom10A1, "Teacher 1 must be HOMEROOM_TEACHER for Class 1 (10A1)");

        // Teacher 1 teaches Math (Subject 1) in Class 1 and Class 2
        boolean teachesMath10A1 = assignmentsT1.stream().anyMatch(
                a -> a.getSchoolClass().getId().equals(1) && a.getSubject() != null && a.getSubject().getId().equals(1));
        boolean teachesMath10A2 = assignmentsT1.stream().anyMatch(
                a -> a.getSchoolClass().getId().equals(2) && a.getSubject() != null && a.getSubject().getId().equals(1));
        assertTrue(teachesMath10A1, "Teacher 1 must teach Math in Class 1");
        assertTrue(teachesMath10A2, "Teacher 1 must teach Math in Class 2");

        // Teacher 2 (teacherId = 2, Nguyen Thi Hien) is Homeroom for Class 2
        List<TeacherAssignment> assignmentsT2 = teacherAssignmentRepository.findByTeacherId(2);
        boolean isHomeroom10A2 = assignmentsT2.stream().anyMatch(
                a -> a.getSchoolClass().getId().equals(2) && "HOMEROOM_TEACHER".equals(a.getRoleType()));
        assertTrue(isHomeroom10A2, "Teacher 2 must be HOMEROOM_TEACHER for Class 2 (10A2)");
    }

    @Test
    @Transactional
    public void testTeacherCanCreateGradeOnlyForAssignedClassAndSubject() {
        // Authenticate as Teacher 1 (teaches Math / Subject 1 in Class 1 and Class 2)
        authenticateUser(8, "teacher_han", "Teacher", null, 1);

        Student student1 = studentRepository.findById(1).orElseThrow(); // Class 1
        Subject subjectMath = subjectRepository.findById(1).orElseThrow(); // Math
        Subject subjectLit = subjectRepository.findById(2).orElseThrow(); // Literature (Taught by Teacher 2)
        SchoolYear year = schoolYearRepository.findById(1).orElseThrow();

        // 1. Teacher 1 creates Math grade for Student 1 (semester 3 to avoid conflict with existing seed)
        Grade mathGrade = new Grade();
        mathGrade.setStudent(student1);
        mathGrade.setSubject(subjectMath);
        mathGrade.setSchoolYear(year);
        mathGrade.setSemester(3);
        mathGrade.setAttendanceScore(9.0);
        mathGrade.setMidtermScore(8.5);
        mathGrade.setFinalScore(9.0);

        Grade created = gradeService.create(mathGrade);
        assertNotNull(created.getId(), "Grade should be created successfully for assigned subject");

        // 2. Teacher 1 attempts to create Literature grade for Student 1 -> Must throw AccessDeniedException (403)
        Grade litGrade = new Grade();
        litGrade.setStudent(student1);
        litGrade.setSubject(subjectLit);
        litGrade.setSchoolYear(year);
        litGrade.setSemester(3);
        litGrade.setAttendanceScore(8.0);
        litGrade.setMidtermScore(8.0);
        litGrade.setFinalScore(8.0);

        assertThrows(AccessDeniedException.class, () -> gradeService.create(litGrade),
                "Teacher 1 must be forbidden from creating Literature grade");
    }

    @Test
    @Transactional
    public void testTeacherCanUpdateGradeOnlyForAssignedSubject() {
        // Authenticate as Teacher 1 (teacherId = 1, teaches Math / Subject 1)
        authenticateUser(8, "teacher_han", "Teacher", null, 1);

        // Find a Math grade (Subject 1) where Teacher 1 teaches Math -> Teacher 1 CAN update
        Grade mathGrade = gradeRepository.findAll().stream()
                .filter(g -> g.getSubject() != null && g.getSubject().getId().equals(1))
                .findFirst().orElseThrow();

        Grade updateData = new Grade();
        updateData.setAttendanceScore(10.0);
        updateData.setMidtermScore(9.5);
        updateData.setFinalScore(10.0);

        Grade updated = gradeService.update(mathGrade.getId(), updateData);
        assertNotNull(updated);
        assertEquals(10.0, updated.getAttendanceScore());

        // Find a literature grade (Subject 2) in Class 1 or 2
        List<Grade> litGrades = gradeRepository.findAll().stream()
                .filter(g -> g.getSubject() != null && g.getSubject().getId().equals(2))
                .toList();
        assertFalse(litGrades.isEmpty(), "Should find literature grades");

        Grade litGrade = litGrades.get(0);
        // Teacher 1 attempts to update Literature grade -> Must throw AccessDeniedException
        assertThrows(AccessDeniedException.class, () -> gradeService.update(litGrade.getId(), updateData),
                "Teacher 1 must be forbidden from updating Literature grade");
    }

    @Test
    public void testHomeroomTeacherReadScopeVsUnassignedScope() {
        // Authenticate as Teacher 1 (Homeroom 10A1, teaches Math)
        authenticateUser(8, "teacher_han", "Teacher", null, 1);

        // Student 1 belongs to Class 10A1
        // Grade 17 is Math -> Teacher 1 can view
        assertDoesNotThrow(() -> gradeService.getById(17));

        // Find Literature grade for Student 1 (Class 10A1)
        List<Grade> student1LitGrades = gradeRepository.findByStudentId(1).stream()
                .filter(g -> g.getSubject() != null && g.getSubject().getId().equals(2))
                .toList();
        if (!student1LitGrades.isEmpty()) {
            Grade s1Lit = student1LitGrades.get(0);
            // Teacher 1 is Homeroom Teacher of Student 1 -> Can view Literature grade (read-only)
            assertDoesNotThrow(() -> gradeService.getById(s1Lit.getId()),
                    "Homeroom teacher should be able to view subject grades of their homeroom students");
        }

        // Student 4 belongs to Class 10A2
        // Find Literature grade for Student 4 (Teacher 1 is NOT homeroom of 10A2 and does NOT teach Lit in 10A2)
        List<Grade> student4LitGrades = gradeRepository.findByStudentId(4).stream()
                .filter(g -> g.getSubject() != null && g.getSubject().getId().equals(2))
                .toList();
        if (!student4LitGrades.isEmpty()) {
            Grade s4Lit = student4LitGrades.get(0);
            assertThrows(AccessDeniedException.class, () -> gradeService.getById(s4Lit.getId()),
                    "Teacher 1 must NOT be allowed to view Literature grades of Class 10A2");
        }
    }

    @Test
    @Transactional
    public void testTeacherCanRecordAttendanceOnlyForAssignedScope() {
        // Authenticate as Teacher 1 (Homeroom of Class 1, teaches Math in Class 1 & 2)
        authenticateUser(8, "teacher_han", "Teacher", null, 1);

        // 1. Record Math attendance for Student 1 (Class 1) -> OK
        AttendanceCreateRequest mathReq = new AttendanceCreateRequest(
                1, 1, 1, LocalDate.now().minusDays(2), 1, "PRESENT", "Math class 1"
        );
        assertDoesNotThrow(() -> attendanceService.recordAttendance(mathReq));

        // 2. Record daily attendance without subject for Class 1 -> OK (Teacher 1 is Homeroom)
        AttendanceCreateRequest homeroomReq = new AttendanceCreateRequest(
                1, 1, null, LocalDate.now().minusDays(2), 2, "PRESENT", "Homeroom daily attendance"
        );
        assertDoesNotThrow(() -> attendanceService.recordAttendance(homeroomReq));

        // 3. Record Literature (Subject 2) attendance for Class 2 -> Forbidden (Teacher 1 not GVCN and not Lit teacher in Class 2)
        AttendanceCreateRequest forbiddenReq = new AttendanceCreateRequest(
                4, 2, 2, LocalDate.now().minusDays(2), 1, "PRESENT", "Lit class 2"
        );
        assertThrows(AccessDeniedException.class, () -> attendanceService.recordAttendance(forbiddenReq),
                "Teacher 1 must be forbidden from recording Literature attendance in Class 2");

        // 4. Student class mismatch: Student 4 (Class 2) submitted with classId = 1 -> BadRequest
        AttendanceCreateRequest mismatchReq = new AttendanceCreateRequest(
                4, 1, 1, LocalDate.now().minusDays(2), 1, "PRESENT", "Mismatch student class"
        );
        assertThrows(IllegalArgumentException.class, () -> attendanceService.recordAttendance(mismatchReq),
                "Mismatched student and class ID must throw IllegalArgumentException");
    }

    @Test
    @Transactional
    public void testLeaveRequestHomeroomTeacherEnforcement() {
        Student student1 = studentRepository.findById(1).orElseThrow(); // Class 10A1 (GVCN: Teacher 1)
        Student student4 = studentRepository.findById(4).orElseThrow(); // Class 10A2 (GVCN: Teacher 2)

        // 1. Create leave request for Student 1
        LeaveRequest req1 = new LeaveRequest();
        req1.setStudent(student1);
        req1.setRequestType("Nghỉ ốm");
        req1.setFromDate(LocalDate.now().plusDays(1));
        req1.setToDate(LocalDate.now().plusDays(2));
        req1.setReason("Sốt cao cần nghỉ");
        req1.setStatus("Chờ duyệt");
        LeaveRequest savedReq1 = leaveRequestRepository.save(req1);

        // 2. Create leave request for Student 4
        LeaveRequest req4 = new LeaveRequest();
        req4.setStudent(student4);
        req4.setRequestType("Việc gia đình");
        req4.setFromDate(LocalDate.now().plusDays(1));
        req4.setToDate(LocalDate.now().plusDays(2));
        req4.setReason("Về quê");
        req4.setStatus("Chờ duyệt");
        LeaveRequest savedReq4 = leaveRequestRepository.save(req4);

        // 3. Authenticate as Teacher 1 (Homeroom of Class 10A1)
        authenticateUser(8, "teacher_han", "Teacher", null, 1);

        // Teacher 1 views all leave requests -> only sees Class 10A1 requests
        List<LeaveRequest> teacher1Requests = leaveRequestService.getAll();
        assertTrue(teacher1Requests.stream().allMatch(r -> r.getStudent().getSchoolClass().getId().equals(1)),
                "Teacher 1 should only see leave requests for Class 10A1");

        // Teacher 1 approves Student 1's request -> OK
        LeaveRequest approved1 = leaveRequestService.updateStatus(savedReq1.getId(), "Đã duyệt", "GVCN đồng ý");
        assertEquals("Đã duyệt", approved1.getStatus());
        assertEquals("GVCN đồng ý", approved1.getAdminNote());

        // Teacher 1 attempts to approve Student 4's request (Class 10A2) -> AccessDeniedException (403)
        assertThrows(AccessDeniedException.class,
                () -> leaveRequestService.updateStatus(savedReq4.getId(), "Đã duyệt", "Fake approval"),
                "Teacher 1 must NOT be allowed to approve leave request for Class 10A2");

        // 4. Authenticate as Teacher 2 (Homeroom of Class 10A2)
        authenticateUser(9, "teacher_hien", "Teacher", null, 2);

        // Teacher 2 approves Student 4's request -> OK
        LeaveRequest approved4 = leaveRequestService.updateStatus(savedReq4.getId(), "Đã duyệt", "GVCN 10A2 duyệt");
        assertEquals("Đã duyệt", approved4.getStatus());

        // 5. Authenticate as Student 1 -> Cannot approve any request
        authenticateUser(2, "student_a", "Student", 1, null);
        assertThrows(AccessDeniedException.class,
                () -> leaveRequestService.updateStatus(savedReq1.getId(), "Đã duyệt", "Student self-approval"),
                "Student must NOT be allowed to approve leave requests");
    }

    @Test
    @Transactional
    public void testTeacherLeaveRequestFlow() {
        // 1. Authenticate as Teacher 1 (userId = 8, teacherId = 1)
        authenticateUser(8, "teacher_han", "Teacher", null, 1);

        LeaveRequest teacherReq = new LeaveRequest();
        teacherReq.setRequestType("Nghỉ phép");
        teacherReq.setFromDate(LocalDate.now().plusDays(1));
        teacherReq.setToDate(LocalDate.now().plusDays(2));
        teacherReq.setReason("Lý do gia đình cần nghỉ phép");

        LeaveRequest saved = leaveRequestService.create(teacherReq);
        assertNotNull(saved.getId());
        assertNotNull(saved.getTeacher());
        assertEquals(1, saved.getTeacher().getId());
        assertNull(saved.getStudent());
        assertEquals("Chờ duyệt", saved.getStatus());

        // Teacher 1 views own requests -> contains saved request
        List<LeaveRequest> myRequests = leaveRequestService.getMyLeaveRequests();
        assertTrue(myRequests.stream().anyMatch(r -> r.getId().equals(saved.getId())));

        // Teacher 1 attempts to self-approve -> AccessDeniedException
        assertThrows(AccessDeniedException.class,
                () -> leaveRequestService.updateStatus(saved.getId(), "Đã duyệt", "Self approve"),
                "Teacher must NOT be allowed to approve own leave request");

        // 2. Authenticate as Teacher 2 (userId = 9, teacherId = 2) -> attempts to approve Teacher 1's request -> AccessDeniedException
        authenticateUser(9, "teacher_hien", "Teacher", null, 2);
        assertThrows(AccessDeniedException.class,
                () -> leaveRequestService.updateStatus(saved.getId(), "Đã duyệt", "Other teacher approve"),
                "Teacher must NOT be allowed to approve other teacher's leave request");

        // 3. Authenticate as Admin (userId = 1) -> Admin approves Teacher's leave request -> OK
        authenticateUser(1, "admin", "Admin", null, null);
        LeaveRequest approvedByAdmin = leaveRequestService.updateStatus(saved.getId(), "Đã duyệt", "BGH đồng ý duyệt đơn");
        assertEquals("Đã duyệt", approvedByAdmin.getStatus());
        assertEquals("BGH đồng ý duyệt đơn", approvedByAdmin.getAdminNote());
    }
}
