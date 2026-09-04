-- ==========================================================
-- Migration Script: Phase 5 - System Hardening & Performance Indexes
-- Target: SQL Server (GradeDB)
-- Description: Idempotent script to add performance indexes for high-frequency queries
--              (Grades, Attendances, LeaveRequests, Notifications).
-- ==========================================================
USE GradeDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Index on Grades for student and subject lookups
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Grades_Student_Subject' AND object_id = OBJECT_ID('dbo.Grades'))
BEGIN
    CREATE INDEX IX_Grades_Student_Subject ON dbo.Grades(StudentID, SubjectID);
    PRINT N'[Migration Phase 5] Index IX_Grades_Student_Subject created.';
END
ELSE
BEGIN
    PRINT N'[Migration Phase 5] Index IX_Grades_Student_Subject already exists.';
END
GO

-- 2. Index on Attendances for class and date queries
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Attendances_Class_Date' AND object_id = OBJECT_ID('dbo.Attendances'))
BEGIN
    CREATE INDEX IX_Attendances_Class_Date ON dbo.Attendances(ClassID, AttendanceDate);
    PRINT N'[Migration Phase 5] Index IX_Attendances_Class_Date created.';
END
ELSE
BEGIN
    PRINT N'[Migration Phase 5] Index IX_Attendances_Class_Date already exists.';
END
GO

-- 3. Index on Attendances for student and date queries
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Attendances_Student_Date' AND object_id = OBJECT_ID('dbo.Attendances'))
BEGIN
    CREATE INDEX IX_Attendances_Student_Date ON dbo.Attendances(StudentID, AttendanceDate);
    PRINT N'[Migration Phase 5] Index IX_Attendances_Student_Date created.';
END
ELSE
BEGIN
    PRINT N'[Migration Phase 5] Index IX_Attendances_Student_Date already exists.';
END
GO

-- 4. Index on LeaveRequests for status filtering
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LeaveRequests_Status' AND object_id = OBJECT_ID('dbo.LeaveRequests'))
BEGIN
    CREATE INDEX IX_LeaveRequests_Status ON dbo.LeaveRequests(Status);
    PRINT N'[Migration Phase 5] Index IX_LeaveRequests_Status created.';
END
ELSE
BEGIN
    PRINT N'[Migration Phase 5] Index IX_LeaveRequests_Status already exists.';
END
GO

-- 5. Index on Notifications for user and read status filtering
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Notifications_User_IsRead' AND object_id = OBJECT_ID('dbo.Notifications'))
BEGIN
    CREATE INDEX IX_Notifications_User_IsRead ON dbo.Notifications(UserID, IsRead);
    PRINT N'[Migration Phase 5] Index IX_Notifications_User_IsRead created.';
END
ELSE
BEGIN
    PRINT N'[Migration Phase 5] Index IX_Notifications_User_IsRead already exists.';
END
GO

PRINT N'[Migration Phase 5] System hardening & performance indexes migration completed successfully!';
