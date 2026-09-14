package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.UnrecordedAttendanceSessionDTO;
import com.jetbrains.grade.model.*;
import com.jetbrains.grade.repository.*;
import com.jetbrains.grade.security.TeacherAssignmentEnforcer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class AttendanceReminderService {

    public static final ZoneId ZONE_VN = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm");

    private final ClassScheduleRepository classScheduleRepository;
    private final AttendanceRepository attendanceRepository;
    private final StudentRepository studentRepository;
    private final NotificationRepository notificationRepository;
    private final NotificationService notificationService;
    private final TeacherAssignmentEnforcer teacherAssignmentEnforcer;

    /**
     * Automatic scheduled scan every 5 minutes from 07:00 to 18:55, Monday to Saturday.
     */
    @Scheduled(cron = "0 */5 7-18 * * MON-SAT", zone = "Asia/Ho_Chi_Minh")
    public void scheduledScanAndRemind() {
        LocalDate today = LocalDate.now(ZONE_VN);
        LocalTime now = LocalTime.now(ZONE_VN);
        log.info("[AttendanceScheduler] Starting automatic attendance scan at {} {}", today, now.format(TIME_FORMATTER));
        int remindedCount = checkAndRemindUnrecordedAttendance(today, now);
        log.info("[AttendanceScheduler] Finished scan. Reminders sent: {}", remindedCount);
    }

    /**
     * Get unrecorded attendance sessions today (Asia/Ho_Chi_Minh timezone).
     */
    @Transactional(readOnly = true)
    public List<UnrecordedAttendanceSessionDTO> getUnrecordedSessionsToday() {
        return getUnrecordedSessions(LocalDate.now(ZONE_VN), LocalTime.now(ZONE_VN));
    }

    /**
     * Core logic: Get unrecorded sessions based on actual ClassSchedule and Student roster.
     */
    @Transactional(readOnly = true)
    public List<UnrecordedAttendanceSessionDTO> getUnrecordedSessions(LocalDate today, LocalTime now) {
        String dayName = today.getDayOfWeek().name();
        DayOfWeekVN dayEnum;
        try {
            dayEnum = DayOfWeekVN.valueOf(dayName);
        } catch (IllegalArgumentException e) {
            log.warn("Invalid DayOfWeek: {}", dayName);
            return List.of();
        }

        List<ClassSchedule> activeSchedules = classScheduleRepository.findActiveSchedulesByDayOfWeekWithDetails(dayEnum);
        List<UnrecordedAttendanceSessionDTO> result = new ArrayList<>();

        for (ClassSchedule schedule : activeSchedules) {
            TimeSlot slot = schedule.getTimeSlot();
            if (slot == null || slot.getStartTime() == null) {
                continue;
            }

            LocalTime startTime = slot.getStartTime();
            LocalTime endTime = slot.getEndTime();

            // Session has not started yet -> not considered unrecorded yet
            if (now.isBefore(startTime)) {
                continue;
            }

            SchoolClass schoolClass = schedule.getSchoolClass();
            if (schoolClass == null) {
                continue;
            }

            long totalStudents = studentRepository.countBySchoolClassId(schoolClass.getId());
            long recordedStudents = attendanceRepository.countBySchoolClassIdAndAttendanceDateAndSlotNumber(
                    schoolClass.getId(), today, slot.getSlotNumber()
            );

            // If class has students and all students have been recorded -> FULLY_ATTENDED
            if (totalStudents > 0 && recordedStudents >= totalStudents) {
                continue;
            }

            // Calculate delay minutes
            long delayMinutes = Math.max(0, Duration.between(startTime, now).toMinutes());
            String delayFormatted;
            if (delayMinutes < 60) {
                delayFormatted = delayMinutes + " phút";
            } else {
                long hours = delayMinutes / 60;
                long mins = delayMinutes % 60;
                delayFormatted = hours + " giờ " + (mins > 0 ? mins + " phút" : "");
            }

            // Attendance status
            String attendanceStatus = (recordedStudents == 0) ? "NOT_ATTENDED" : "PARTIALLY_ATTENDED";

            // Alert status:
            // - QUA_HAN: after endTime
            // - CANH_BAO_TRE: delay >= 10 minutes and before or at endTime
            // - CHUA_TRE: delay < 10 minutes (grace period right after startTime)
            String alertStatus;
            String alertStatusLabel;
            if (endTime != null && now.isAfter(endTime)) {
                alertStatus = "QUA_HAN";
                alertStatusLabel = "Quá hạn";
            } else if (delayMinutes >= 10) {
                alertStatus = "CANH_BAO_TRE";
                alertStatusLabel = "Cảnh báo trễ";
            } else {
                alertStatus = "CHUA_TRE";
                alertStatusLabel = "Chờ điểm danh";
            }

            Teacher teacher = schedule.getTeacher();
            boolean reminderSent = false;
            if (teacher != null && teacher.getUser() != null) {
                reminderSent = notificationRepository.existsReminderSentToday(
                        teacher.getUser().getId(),
                        "ATTENDANCE_ALERT",
                        schedule.getId(),
                        today.atStartOfDay()
                );
            }

            result.add(UnrecordedAttendanceSessionDTO.builder()
                    .scheduleId(schedule.getId())
                    .classId(schoolClass.getId())
                    .className(schoolClass.getClassName())
                    .subjectId(schedule.getSubject() != null ? schedule.getSubject().getId() : null)
                    .subjectName(schedule.getSubject() != null ? schedule.getSubject().getSubjectName() : null)
                    .teacherId(teacher != null ? teacher.getId() : null)
                    .teacherName(teacher != null ? teacher.getFullName() : "Chưa phân công")
                    .slotNumber(slot.getSlotNumber())
                    .startTime(startTime)
                    .endTime(endTime)
                    .totalStudents(totalStudents)
                    .recordedStudents(recordedStudents)
                    .delayMinutes(delayMinutes)
                    .delayFormatted(delayFormatted)
                    .attendanceStatus(attendanceStatus)
                    .alertStatus(alertStatus)
                    .alertStatusLabel(alertStatusLabel)
                    .reminderSent(reminderSent)
                    .build());
        }

        return result;
    }

    /**
     * Scan and send notifications for unrecorded sessions (default today at current time).
     */
    @Transactional
    public int checkAndRemindUnrecordedAttendance() {
        return checkAndRemindUnrecordedAttendance(LocalDate.now(ZONE_VN), LocalTime.now(ZONE_VN));
    }

    /**
     * Core scan & send notification method with deterministic parameters for testing.
     */
    @Transactional
    public int checkAndRemindUnrecordedAttendance(LocalDate today, LocalTime now) {
        List<UnrecordedAttendanceSessionDTO> unrecorded = getUnrecordedSessions(today, now);
        int remindedCount = 0;

        for (UnrecordedAttendanceSessionDTO item : unrecorded) {
            // Only send reminder if delay >= 10 minutes
            if (item.getDelayMinutes() == null || item.getDelayMinutes() < 10) {
                continue;
            }

            ClassSchedule schedule = classScheduleRepository.findById(item.getScheduleId()).orElse(null);
            if (schedule == null || schedule.getTeacher() == null) {
                continue;
            }

            Teacher teacher = schedule.getTeacher();
            User teacherUser = teacher.getUser();
            if (teacherUser == null) {
                log.warn("Teacher {} (ID: {}) has no associated User account. Skipping notification.",
                        teacher.getFullName(), teacher.getId());
                continue;
            }

            // Anti-spam: max 1 notification per schedule per day
            boolean alreadySent = notificationRepository.existsReminderSentToday(
                    teacherUser.getId(),
                    "ATTENDANCE_ALERT",
                    schedule.getId(),
                    today.atStartOfDay()
            );

            if (alreadySent) {
                continue;
            }

            String startTimeStr = item.getStartTime() != null ? item.getStartTime().format(TIME_FORMATTER) : "";
            String body;
            if (item.getRecordedStudents() != null && item.getRecordedStudents() > 0) {
                body = String.format(
                        "Bạn chưa hoàn tất điểm danh lớp %s - %s (đã ghi nhận %d/%d học sinh), tiết học bắt đầu lúc %s.",
                        item.getClassName(),
                        item.getSubjectName() != null ? item.getSubjectName() : "Môn học",
                        item.getRecordedStudents(),
                        item.getTotalStudents() != null ? item.getTotalStudents() : 0,
                        startTimeStr
                );
            } else {
                body = String.format(
                        "Bạn chưa điểm danh lớp %s - %s, tiết học bắt đầu lúc %s.",
                        item.getClassName(),
                        item.getSubjectName() != null ? item.getSubjectName() : "Môn học",
                        startTimeStr
                );
            }

            notificationService.createNotification(
                    teacherUser,
                    "Nhắc nhở điểm danh",
                    body,
                    "ATTENDANCE_ALERT",
                    schedule.getId()
            );

            remindedCount++;
            log.info("Sent attendance reminder to Teacher {} (UserID: {}) for Class {} - Subject {} (ScheduleID: {})",
                    teacher.getFullName(), teacherUser.getId(), item.getClassName(), item.getSubjectName(), schedule.getId());
        }

        return remindedCount;
    }
}
