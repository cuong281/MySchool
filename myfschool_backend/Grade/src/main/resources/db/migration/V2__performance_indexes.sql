-- ==========================================================
-- Flyway Migration V2: Performance Indexes
-- ==========================================================

-- 1. Index on Grades for student and subject lookups
CREATE INDEX IX_Grades_Student_Subject ON Grades(StudentID, SubjectID);

-- 2. Index on Attendances for class and date queries
CREATE INDEX IX_Attendances_Class_Date ON Attendances(ClassID, AttendanceDate);

-- 3. Index on Attendances for student and date queries
CREATE INDEX IX_Attendances_Student_Date ON Attendances(StudentID, AttendanceDate);

-- 4. Index on LeaveRequests for status filtering
CREATE INDEX IX_LeaveRequests_Status ON LeaveRequests(Status);

-- 5. Index on Notifications for user and read status filtering
CREATE INDEX IX_Notifications_User_IsRead ON Notifications(UserID, IsRead);
