package com.jetbrains.grade;

import com.jetbrains.grade.dto.AttendanceBatchItemDTO;
import com.jetbrains.grade.dto.AttendanceBatchRequest;
import com.jetbrains.grade.dto.AttendanceSheetDTO;
import com.jetbrains.grade.exception.LeaveConflictException;
import com.jetbrains.grade.model.*;
import com.jetbrains.grade.repository.*;
import com.jetbrains.grade.security.CustomUserDetails;
import com.jetbrains.grade.service.AttendanceService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class AttendanceFeatureTest {

    @Autowired
    private AttendanceService attendanceService;

    @Autowired
    private AttendanceRepository attendanceRepository;

    @Autowired
    private StudentRepository studentRepository;

    @Autowired
    private SchoolClassRepository schoolClassRepository;

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private TimeSlotRepository timeSlotRepository;

    @Autowired
    private LeaveRequestRepository leaveRequestRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TeacherRepository teacherRepository;

    @Autowired
    private ClassScheduleRepository classScheduleRepository;

    @Autowired
    private com.jetbrains.grade.controller.AttendanceController attendanceController;

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

    @AfterEach
    public void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @Transactional
    public void testAttendanceSheet_ReadOnly_NoSideEffects() {
        // Authenticate as Admin
        authenticateUser(1, "admin", "Admin", null, null);

        SchoolClass sc = schoolClassRepository.findAll().get(0);
        long countBefore = attendanceRepository.count();

        AttendanceSheetDTO sheet = attendanceService.getAttendanceSheet(sc.getId(), null, 1, LocalDate.now());

        long countAfter = attendanceRepository.count();
        assertEquals(countBefore, countAfter, "getAttendanceSheet MUST NEVER insert records into database!");
        assertNotNull(sheet);
        assertEquals(sc.getId(), sheet.getClassId());
        assertFalse(sheet.getStudents().isEmpty());
    }

    @Test
    @Transactional
    public void testAttendanceBatch_TimeLockdown_PastDay_TeacherForbidden() {
        // Teacher 1 (Homeroom teacher for 10A1)
        authenticateUser(2, "teacher1", "Teacher", null, 1);

        SchoolClass sc = schoolClassRepository.findAll().get(0);
        List<Student> students = studentRepository.findBySchoolClassId(sc.getId());
        Student st = students.get(0);

        AttendanceBatchRequest req = AttendanceBatchRequest.builder()
                .classId(sc.getId())
                .slotNumber(1)
                .attendanceDate(LocalDate.now().minusDays(1)) // Past day
                .items(List.of(AttendanceBatchItemDTO.builder()
                        .studentId(st.getId())
                        .status("PRESENT")
                        .build()))
                .build();

        AccessDeniedException ex = assertThrows(AccessDeniedException.class, () -> {
            attendanceService.recordBatchAttendance(req);
        });
        assertTrue(ex.getMessage().contains("chỉ xem") || ex.getMessage().contains("khóa"),
                "Expected past day lock message, got: " + ex.getMessage());
    }

    @Test
    @Transactional
    public void testAttendanceBatch_TimeLockdown_FutureDay_TeacherBadRequest() {
        authenticateUser(2, "teacher1", "Teacher", null, 1);

        SchoolClass sc = schoolClassRepository.findAll().get(0);
        List<Student> students = studentRepository.findBySchoolClassId(sc.getId());
        Student st = students.get(0);

        AttendanceBatchRequest req = AttendanceBatchRequest.builder()
                .classId(sc.getId())
                .slotNumber(1)
                .attendanceDate(LocalDate.now().plusDays(1)) // Future day
                .items(List.of(AttendanceBatchItemDTO.builder()
                        .studentId(st.getId())
                        .status("PRESENT")
                        .build()))
                .build();

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> {
            attendanceService.recordBatchAttendance(req);
        });
        assertTrue(ex.getMessage().contains("tương lai"), "Expected future day rejection, got: " + ex.getMessage());
    }

    @Test
    @Transactional
    public void testAttendanceBatch_TimeLockdown_SlotStartTime_TeacherBeforeSlot() {
        authenticateUser(2, "teacher1", "Teacher", null, 1);

        SchoolClass sc = schoolClassRepository.findAll().get(0);
        List<Student> students = studentRepository.findBySchoolClassId(sc.getId());
        Student st = students.get(0);

        // Find or configure a slot whose startTime is in the future today (e.g. 23:58)
        TimeSlot futureSlot = new TimeSlot();
        futureSlot.setSlotNumber(99);
        futureSlot.setStartTime(LocalTime.of(23, 58));
        futureSlot.setEndTime(LocalTime.of(23, 59));
        futureSlot.setSessionType(SessionType.AFTERNOON);
        futureSlot.setIsActive(true);
        futureSlot = timeSlotRepository.save(futureSlot);

        AttendanceBatchRequest req = AttendanceBatchRequest.builder()
                .classId(sc.getId())
                .slotNumber(99)
                .attendanceDate(LocalDate.now())
                .items(List.of(AttendanceBatchItemDTO.builder()
                        .studentId(st.getId())
                        .status("PRESENT")
                        .build()))
                .build();

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> {
            attendanceService.recordBatchAttendance(req);
        });
        assertTrue(ex.getMessage().contains("Chưa đến thời gian bắt đầu tiết học"),
                "Expected not started exception, got: " + ex.getMessage());
    }

    @Test
    @Transactional
    public void testAttendanceBatch_ApprovedLeaveConflict_WithoutOverride_Throws409() {
        authenticateUser(1, "admin", "Admin", null, null);

        SchoolClass sc = schoolClassRepository.findAll().get(0);
        List<Student> students = studentRepository.findBySchoolClassId(sc.getId());
        Student st = students.get(0);
        if (st.getSchoolClass() == null) {
            st.setSchoolClass(sc);
            st = studentRepository.saveAndFlush(st);
        }

        // Create an approved leave for student covering today
        LeaveRequest lr = new LeaveRequest();
        lr.setStudent(st);
        lr.setRequestType("Nghỉ ốm");
        lr.setFromDate(LocalDate.now().minusDays(1));
        lr.setToDate(LocalDate.now().plusDays(1));
        lr.setReason("Sốt phát ban");
        lr.setStatus("Đã duyệt");
        lr = leaveRequestRepository.saveAndFlush(lr);

        AttendanceBatchRequest req = AttendanceBatchRequest.builder()
                .classId(sc.getId())
                .slotNumber(1)
                .attendanceDate(LocalDate.now())
                .items(List.of(AttendanceBatchItemDTO.builder()
                        .studentId(st.getId())
                        .status("PRESENT") // Attempting to mark present without override
                        .overrideLeave(false)
                        .build()))
                .build();

        LeaveConflictException ex = assertThrows(LeaveConflictException.class, () -> {
            attendanceService.recordBatchAttendance(req);
        });

        assertEquals(st.getId(), ex.getStudentId());
        assertNotNull(ex.getLeaveRequestId());
        assertTrue(ex.getMessage().contains("đơn xin nghỉ phép được duyệt"));
    }

    @Test
    @Transactional
    public void testAttendanceBatch_ApprovedLeaveConflict_WithOverrideInvalidReason_Throws409() {
        authenticateUser(1, "admin", "Admin", null, null);

        SchoolClass sc = schoolClassRepository.findAll().get(0);
        List<Student> students = studentRepository.findBySchoolClassId(sc.getId());
        Student st = students.get(0);
        if (st.getSchoolClass() == null) {
            st.setSchoolClass(sc);
            st = studentRepository.saveAndFlush(st);
        }

        LeaveRequest lr = new LeaveRequest();
        lr.setStudent(st);
        lr.setRequestType("Nghỉ ốm");
        lr.setFromDate(LocalDate.now().minusDays(1));
        lr.setToDate(LocalDate.now().plusDays(1));
        lr.setReason("Sốt");
        lr.setStatus("APPROVED");
        lr = leaveRequestRepository.saveAndFlush(lr);

        // Case 1: reason length < 3 chars
        AttendanceBatchRequest reqShort = AttendanceBatchRequest.builder()
                .classId(sc.getId())
                .slotNumber(1)
                .attendanceDate(LocalDate.now())
                .items(List.of(AttendanceBatchItemDTO.builder()
                        .studentId(st.getId())
                        .status("PRESENT")
                        .overrideLeave(true)
                        .overrideReason("ok") // only 2 chars
                        .build()))
                .build();

        assertThrows(LeaveConflictException.class, () -> {
            attendanceService.recordBatchAttendance(reqShort);
        });

        // Case 2: reason length > 150 chars
        String longReason = "A".repeat(151);
        AttendanceBatchRequest reqLong = AttendanceBatchRequest.builder()
                .classId(sc.getId())
                .slotNumber(1)
                .attendanceDate(LocalDate.now())
                .items(List.of(AttendanceBatchItemDTO.builder()
                        .studentId(st.getId())
                        .status("PRESENT")
                        .overrideLeave(true)
                        .overrideReason(longReason)
                        .build()))
                .build();

        assertThrows(LeaveConflictException.class, () -> {
            attendanceService.recordBatchAttendance(reqLong);
        });
    }

    @Test
    @Transactional
    public void testAttendanceBatch_ApprovedLeaveConflict_WithValidOverride_SucceedsAndAudit() {
        authenticateUser(1, "admin", "Admin", null, null);

        SchoolClass sc = schoolClassRepository.findAll().get(0);
        List<Student> students = studentRepository.findBySchoolClassId(sc.getId());
        Student st = students.get(0);
        if (st.getSchoolClass() == null) {
            st.setSchoolClass(sc);
            st = studentRepository.saveAndFlush(st);
        }

        LeaveRequest lr = new LeaveRequest();
        lr.setStudent(st);
        lr.setRequestType("Nghỉ ốm");
        lr.setFromDate(LocalDate.now().minusDays(1));
        lr.setToDate(LocalDate.now().plusDays(1));
        lr.setReason("Sốt");
        lr.setStatus("Đã duyệt");
        lr = leaveRequestRepository.saveAndFlush(lr);

        String validReason = "Phụ huynh báo em đã khỏi ốm và đến lớp";
        AttendanceBatchRequest req = AttendanceBatchRequest.builder()
                .classId(sc.getId())
                .slotNumber(1)
                .attendanceDate(LocalDate.now())
                .items(List.of(AttendanceBatchItemDTO.builder()
                        .studentId(st.getId())
                        .status("PRESENT")
                        .overrideLeave(true)
                        .overrideReason(validReason)
                        .build()))
                .build();

        var result = attendanceService.recordBatchAttendance(req);
        assertNotNull(result);
        assertEquals(1, result.size());

        Attendance saved = attendanceRepository.findByStudentIdAndAttendanceDateAndSlotNumber(st.getId(), LocalDate.now(), 1)
                .orElseThrow();
        assertEquals("PRESENT", saved.getStatus());
        assertNotNull(saved.getNote());
        assertTrue(saved.getNote().contains("[GHI ĐÈ ĐƠN NGHỈ #"));
        assertTrue(saved.getNote().contains(validReason));
    }

    @Test
    @Transactional
    public void testAttendanceBatch_UpdatePreservesRecordedByUserID() {
        SchoolClass sc = schoolClassRepository.findAll().get(0);
        List<Student> students = studentRepository.findBySchoolClassId(sc.getId());
        Student st = students.size() > 1 ? students.get(1) : students.get(0);

        TimeSlot openSlot = new TimeSlot();
        openSlot.setSlotNumber(98);
        openSlot.setStartTime(LocalTime.of(0, 0));
        openSlot.setEndTime(LocalTime.of(23, 59));
        openSlot.setSessionType(SessionType.MORNING);
        openSlot.setIsActive(true);
        openSlot = timeSlotRepository.saveAndFlush(openSlot);

        Teacher teacher1 = teacherRepository.findById(1).orElseThrow();
        com.jetbrains.grade.model.ClassSchedule testSchedule = new com.jetbrains.grade.model.ClassSchedule();
        testSchedule.setSchoolClass(sc);
        testSchedule.setTimeSlot(openSlot);
        testSchedule.setTeacher(teacher1);
        testSchedule.setSubject(subjectRepository.findAll().get(0));
        testSchedule.setDayOfWeek(com.jetbrains.grade.model.DayOfWeekVN.valueOf(LocalDate.now().getDayOfWeek().name()));
        testSchedule.setStatus("ACTIVE");
        classScheduleRepository.saveAndFlush(testSchedule);

        // User 1 creates attendance
        authenticateUser(1, "admin", "Admin", null, null);

        AttendanceBatchRequest reqCreate = AttendanceBatchRequest.builder()
                .classId(sc.getId())
                .slotNumber(98)
                .attendanceDate(LocalDate.now())
                .items(List.of(AttendanceBatchItemDTO.builder()
                        .studentId(st.getId())
                        .status("EXCUSED_ABSENCE")
                        .build()))
                .build();

        attendanceService.recordBatchAttendance(reqCreate);

        Attendance initial = attendanceRepository.findByStudentIdAndAttendanceDateAndSlotNumber(st.getId(), LocalDate.now(), 98)
                .orElseThrow();
        Integer initialCreatorUserId = initial.getRecordedBy().getId();
        assertEquals(1, initialCreatorUserId);

        // User 2 (Teacher 1) updates attendance
        teacher1 = teacherRepository.findById(1).orElseThrow();
        authenticateUser(teacher1.getUser().getId(), teacher1.getUser().getUsername(), "Teacher", null, 1);

        AttendanceBatchRequest reqUpdate = AttendanceBatchRequest.builder()
                .classId(sc.getId())
                .slotNumber(98)
                .attendanceDate(LocalDate.now())
                .items(List.of(AttendanceBatchItemDTO.builder()
                        .studentId(st.getId())
                        .status("EXCUSED_ABSENCE")
                        .note("Giáo viên xác nhận")
                        .build()))
                .build();

        attendanceService.recordBatchAttendance(reqUpdate);

        Attendance updated = attendanceRepository.findByStudentIdAndAttendanceDateAndSlotNumber(st.getId(), LocalDate.now(), 98)
                .orElseThrow();
        assertEquals("EXCUSED_ABSENCE", updated.getStatus());
        assertEquals(initialCreatorUserId, updated.getRecordedBy().getId(),
                "RecordedByUserID MUST BE PRESERVED when an attendance record is updated!");
    }

    @Test
    public void testAdminAccessToUnrecordedAlerts() {
        authenticateUser(1, "admin", "Admin", null, null);
        var res = attendanceController.getUnrecordedAttendanceSessionsToday();
        assertEquals(200, res.getStatusCode().value());
        assertNotNull(res.getBody());

        var scanRes = attendanceController.scanAndRemindUnrecordedAttendance();
        assertEquals(200, scanRes.getStatusCode().value());
        assertNotNull(scanRes.getBody());
        assertTrue(scanRes.getBody().containsKey("remindedCount"));
    }
}
