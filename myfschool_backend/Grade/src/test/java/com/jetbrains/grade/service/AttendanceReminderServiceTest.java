package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.UnrecordedAttendanceSessionDTO;
import com.jetbrains.grade.model.*;
import com.jetbrains.grade.repository.*;
import com.jetbrains.grade.security.TeacherAssignmentEnforcer;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class AttendanceReminderServiceTest {

    @Mock
    private ClassScheduleRepository classScheduleRepository;

    @Mock
    private AttendanceRepository attendanceRepository;

    @Mock
    private StudentRepository studentRepository;

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private NotificationService notificationService;

    @Mock
    private TeacherAssignmentEnforcer teacherAssignmentEnforcer;

    @InjectMocks
    private AttendanceReminderService attendanceReminderService;

    private LocalDate testDate;
    private DayOfWeekVN testDayEnum;
    private SchoolClass class10A1;
    private Subject mathSubject;
    private Teacher teacherA;
    private User teacherUserA;
    private TimeSlot slot3;
    private ClassSchedule schedule1;

    @BeforeEach
    void setUp() {
        // Assume Monday 2026-03-23
        testDate = LocalDate.of(2026, 3, 23);
        testDayEnum = DayOfWeekVN.MONDAY;

        class10A1 = new SchoolClass();
        class10A1.setId(1);
        class10A1.setClassName("10A1");

        mathSubject = new Subject();
        mathSubject.setId(10);
        mathSubject.setSubjectName("Toán");

        teacherUserA = new User();
        teacherUserA.setId(100);
        teacherUserA.setUsername("teacher_a");

        teacherA = new Teacher();
        teacherA.setId(20);
        teacherA.setFullName("Nguyễn Văn A");
        teacherA.setUser(teacherUserA);

        slot3 = new TimeSlot();
        slot3.setId(3);
        slot3.setSlotNumber(3);
        slot3.setStartTime(LocalTime.of(9, 0));
        slot3.setEndTime(LocalTime.of(9, 45));

        schedule1 = new ClassSchedule();
        schedule1.setId(501);
        schedule1.setSchoolClass(class10A1);
        schedule1.setSubject(mathSubject);
        schedule1.setTeacher(teacherA);
        schedule1.setTimeSlot(slot3);
        schedule1.setDayOfWeek(DayOfWeekVN.MONDAY);
        schedule1.setStatus("ACTIVE");
    }

    @Test
    @DisplayName("1. Chưa điểm danh quá 10 phút -> Gửi đúng 1 notification cho giáo viên phụ trách")
    void testUnrecordedAttendance_TriggersNotification_WhenDelayOver10Minutes() {
        // Time now is 09:15 (15 mins late)
        LocalTime now = LocalTime.of(9, 15);

        when(classScheduleRepository.findActiveSchedulesByDayOfWeekWithDetails(testDayEnum))
                .thenReturn(List.of(schedule1));
        when(classScheduleRepository.findById(schedule1.getId()))
                .thenReturn(Optional.of(schedule1));
        when(studentRepository.countBySchoolClassId(1)).thenReturn(30L);
        when(attendanceRepository.countBySchoolClassIdAndAttendanceDateAndSlotNumber(1, testDate, 3)).thenReturn(0L);
        when(notificationRepository.existsReminderSentToday(eq(100), eq("ATTENDANCE_ALERT"), eq(501), any(LocalDateTime.class)))
                .thenReturn(false);

        // Act
        int remindedCount = attendanceReminderService.checkAndRemindUnrecordedAttendance(testDate, now);

        // Assert
        assertEquals(1, remindedCount, "Phải gửi 1 thông báo nhắc nhở");

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        ArgumentCaptor<String> titleCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> bodyCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> typeCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<Integer> refCaptor = ArgumentCaptor.forClass(Integer.class);

        verify(notificationService, times(1)).createNotification(
                userCaptor.capture(),
                titleCaptor.capture(),
                bodyCaptor.capture(),
                typeCaptor.capture(),
                refCaptor.capture()
        );

        assertEquals(100, userCaptor.getValue().getId());
        assertEquals("Nhắc nhở điểm danh", titleCaptor.getValue());
        assertEquals("Bạn chưa điểm danh lớp 10A1 - Toán, tiết học bắt đầu lúc 09:00.", bodyCaptor.getValue());
        assertEquals("ATTENDANCE_ALERT", typeCaptor.getValue());
        assertEquals(501, refCaptor.getValue());
    }

    @Test
    @DisplayName("2. Đã điểm danh đầy đủ -> Không gửi notification và không hiển thị trong danh sách cảnh báo")
    void testRecordedAttendance_DoesNotTriggerNotification() {
        LocalTime now = LocalTime.of(9, 15);

        when(classScheduleRepository.findActiveSchedulesByDayOfWeekWithDetails(testDayEnum))
                .thenReturn(List.of(schedule1));
        when(studentRepository.countBySchoolClassId(1)).thenReturn(30L);
        // All 30 students recorded
        when(attendanceRepository.countBySchoolClassIdAndAttendanceDateAndSlotNumber(1, testDate, 3)).thenReturn(30L);

        // Act
        List<UnrecordedAttendanceSessionDTO> unrecorded = attendanceReminderService.getUnrecordedSessions(testDate, now);
        int remindedCount = attendanceReminderService.checkAndRemindUnrecordedAttendance(testDate, now);

        // Assert
        assertTrue(unrecorded.isEmpty(), "Lớp đã điểm danh đầy đủ thì danh sách chưa điểm danh phải rỗng");
        assertEquals(0, remindedCount, "Không được gửi thông báo cho buổi đã điểm danh");
        verify(notificationService, never()).createNotification(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("3. Chống spam: Không gửi notification trùng cho cùng một buổi học trong ngày")
    void testNoSpamDuplicateNotification_WhenAlreadySentToday() {
        LocalTime now = LocalTime.of(9, 20);

        when(classScheduleRepository.findActiveSchedulesByDayOfWeekWithDetails(testDayEnum))
                .thenReturn(List.of(schedule1));
        when(classScheduleRepository.findById(schedule1.getId()))
                .thenReturn(Optional.of(schedule1));
        when(studentRepository.countBySchoolClassId(1)).thenReturn(30L);
        when(attendanceRepository.countBySchoolClassIdAndAttendanceDateAndSlotNumber(1, testDate, 3)).thenReturn(0L);

        // Mock already sent earlier today
        when(notificationRepository.existsReminderSentToday(eq(100), eq("ATTENDANCE_ALERT"), eq(501), any(LocalDateTime.class)))
                .thenReturn(true);

        // Act
        int remindedCount = attendanceReminderService.checkAndRemindUnrecordedAttendance(testDate, now);

        // Assert
        assertEquals(0, remindedCount, "Không được gửi lại nếu đã gửi nhắc nhở hôm nay");
        verify(notificationService, never()).createNotification(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("4. Nhiều giáo viên/lớp: Xử lý độc lập, chỉ gửi đúng cho giáo viên và lớp trễ")
    void testMultipleTeachersAndClasses_HandledIndependently() {
        LocalTime now = LocalTime.of(9, 15);

        // Schedule 2: Class 10A2 - Văn (Teacher B, Fully Attended 30/30)
        SchoolClass class10A2 = new SchoolClass();
        class10A2.setId(2);
        class10A2.setClassName("10A2");
        Subject litSubject = new Subject();
        litSubject.setId(11);
        litSubject.setSubjectName("Ngữ Văn");
        User userB = new User();
        userB.setId(101);
        userB.setUsername("teacher_b");
        Teacher teacherB = new Teacher();
        teacherB.setId(21);
        teacherB.setUser(userB);
        teacherB.setFullName("Trần Thị B");
        ClassSchedule schedule2 = new ClassSchedule();
        schedule2.setId(502);
        schedule2.setSchoolClass(class10A2);
        schedule2.setDayOfWeek(DayOfWeekVN.MONDAY);
        schedule2.setTimeSlot(slot3);
        schedule2.setSubject(litSubject);
        schedule2.setTeacher(teacherB);
        schedule2.setStatus("ACTIVE");

        // Schedule 3: Class 10A3 - Lý (Teacher C, Slot starts at 09:10 -> delay 5m < 10m Grace Period)
        TimeSlot slotGrace = new TimeSlot();
        slotGrace.setId(4);
        slotGrace.setSlotNumber(4);
        slotGrace.setStartTime(LocalTime.of(9, 10));
        slotGrace.setEndTime(LocalTime.of(9, 55));
        SchoolClass class10A3 = new SchoolClass();
        class10A3.setId(3);
        class10A3.setClassName("10A3");
        Subject physSubject = new Subject();
        physSubject.setId(12);
        physSubject.setSubjectName("Vật Lý");
        User userC = new User();
        userC.setId(102);
        userC.setUsername("teacher_c");
        Teacher teacherC = new Teacher();
        teacherC.setId(22);
        teacherC.setUser(userC);
        teacherC.setFullName("Lê Văn C");
        ClassSchedule schedule3 = new ClassSchedule();
        schedule3.setId(503);
        schedule3.setSchoolClass(class10A3);
        schedule3.setDayOfWeek(DayOfWeekVN.MONDAY);
        schedule3.setTimeSlot(slotGrace);
        schedule3.setSubject(physSubject);
        schedule3.setTeacher(teacherC);
        schedule3.setStatus("ACTIVE");

        // Schedule 4: Class 10A4 - Hóa (Teacher D, 15m delay, Partially Attended 10/30)
        SchoolClass class10A4 = new SchoolClass();
        class10A4.setId(4);
        class10A4.setClassName("10A4");
        Subject chemSubject = new Subject();
        chemSubject.setId(13);
        chemSubject.setSubjectName("Hóa Học");
        User userD = new User();
        userD.setId(103);
        userD.setUsername("teacher_d");
        Teacher teacherD = new Teacher();
        teacherD.setId(23);
        teacherD.setUser(userD);
        teacherD.setFullName("Phạm Thị D");
        ClassSchedule schedule4 = new ClassSchedule();
        schedule4.setId(504);
        schedule4.setSchoolClass(class10A4);
        schedule4.setDayOfWeek(DayOfWeekVN.MONDAY);
        schedule4.setTimeSlot(slot3);
        schedule4.setSubject(chemSubject);
        schedule4.setTeacher(teacherD);
        schedule4.setStatus("ACTIVE");

        when(classScheduleRepository.findActiveSchedulesByDayOfWeekWithDetails(testDayEnum))
                .thenReturn(List.of(schedule1, schedule2, schedule3, schedule4));

        when(classScheduleRepository.findById(501)).thenReturn(Optional.of(schedule1));
        when(classScheduleRepository.findById(504)).thenReturn(Optional.of(schedule4));

        when(studentRepository.countBySchoolClassId(1)).thenReturn(30L);
        when(studentRepository.countBySchoolClassId(2)).thenReturn(30L);
        when(studentRepository.countBySchoolClassId(3)).thenReturn(30L);
        when(studentRepository.countBySchoolClassId(4)).thenReturn(30L);

        // 10A1: 0/30
        when(attendanceRepository.countBySchoolClassIdAndAttendanceDateAndSlotNumber(1, testDate, 3)).thenReturn(0L);
        // 10A2: 30/30 (full)
        when(attendanceRepository.countBySchoolClassIdAndAttendanceDateAndSlotNumber(2, testDate, 3)).thenReturn(30L);
        // 10A3: 0/30 (grace period, delay = 5m)
        when(attendanceRepository.countBySchoolClassIdAndAttendanceDateAndSlotNumber(3, testDate, 4)).thenReturn(0L);
        // 10A4: 10/30 (partial)
        when(attendanceRepository.countBySchoolClassIdAndAttendanceDateAndSlotNumber(4, testDate, 3)).thenReturn(10L);

        when(notificationRepository.existsReminderSentToday(anyInt(), eq("ATTENDANCE_ALERT"), anyInt(), any(LocalDateTime.class))).thenReturn(false);

        // Act
        List<UnrecordedAttendanceSessionDTO> unrecorded = attendanceReminderService.getUnrecordedSessions(testDate, now);
        int remindedCount = attendanceReminderService.checkAndRemindUnrecordedAttendance(testDate, now);

        // Assert
        // Unrecorded should contain 10A1 (0/30), 10A3 (0/30 in grace), 10A4 (10/30 partial) = 3 sessions
        assertEquals(3, unrecorded.size());
        // Only 10A1 and 10A4 have delay >= 10 minutes -> 2 reminders sent
        assertEquals(2, remindedCount);

        verify(notificationService, times(1)).createNotification(
                eq(teacherUserA),
                eq("Nhắc nhở điểm danh"),
                contains("Bạn chưa điểm danh lớp 10A1 - Toán"),
                eq("ATTENDANCE_ALERT"),
                eq(501)
        );

        verify(notificationService, times(1)).createNotification(
                eq(userD),
                eq("Nhắc nhở điểm danh"),
                contains("Bạn chưa hoàn tất điểm danh lớp 10A4 - Hóa Học (đã ghi nhận 10/30 học sinh)"),
                eq("ATTENDANCE_ALERT"),
                eq(504)
        );

        // Teacher B and C never notified
        verify(notificationService, never()).createNotification(eq(userB), any(), any(), any(), any());
        verify(notificationService, never()).createNotification(eq(userC), any(), any(), any(), any());
    }

    @Test
    @DisplayName("5. Phân quyền và định dạng trạng thái: Trễ < 10m là CHUA_TRE, >= 10m là CANH_BAO_TRE, qua endTime là QUA_HAN")
    void testAlertStatusClassification() {
        // Case A: Grace period (delay = 5m)
        LocalTime nowGrace = LocalTime.of(9, 5);
        when(classScheduleRepository.findActiveSchedulesByDayOfWeekWithDetails(testDayEnum))
                .thenReturn(List.of(schedule1));
        when(studentRepository.countBySchoolClassId(1)).thenReturn(30L);
        when(attendanceRepository.countBySchoolClassIdAndAttendanceDateAndSlotNumber(1, testDate, 3)).thenReturn(0L);

        List<UnrecordedAttendanceSessionDTO> listA = attendanceReminderService.getUnrecordedSessions(testDate, nowGrace);
        assertEquals(1, listA.size());
        assertEquals("CHUA_TRE", listA.get(0).getAlertStatus());
        assertEquals("Chờ điểm danh", listA.get(0).getAlertStatusLabel());

        // Case B: In session and late (delay = 15m, before endTime 09:45)
        LocalTime nowLate = LocalTime.of(9, 15);
        List<UnrecordedAttendanceSessionDTO> listB = attendanceReminderService.getUnrecordedSessions(testDate, nowLate);
        assertEquals("CANH_BAO_TRE", listB.get(0).getAlertStatus());
        assertEquals("Cảnh báo trễ", listB.get(0).getAlertStatusLabel());

        // Case C: Session ended (09:50 > endTime 09:45)
        LocalTime nowExpired = LocalTime.of(9, 50);
        List<UnrecordedAttendanceSessionDTO> listC = attendanceReminderService.getUnrecordedSessions(testDate, nowExpired);
        assertEquals("QUA_HAN", listC.get(0).getAlertStatus());
        assertEquals("Quá hạn", listC.get(0).getAlertStatusLabel());
    }
}
