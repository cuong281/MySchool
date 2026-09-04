-- Migration Phase 3: Attendance, Notifications, and User Device Tokens
USE GradeDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Attendances Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Attendances')
BEGIN
    CREATE TABLE dbo.Attendances (
        AttendanceID INT IDENTITY(1,1) PRIMARY KEY,
        StudentID INT NOT NULL CONSTRAINT FK_Attendances_Students FOREIGN KEY REFERENCES dbo.Students(StudentID),
        ClassID INT NOT NULL CONSTRAINT FK_Attendances_Classes FOREIGN KEY REFERENCES dbo.SchoolClasses(ClassID),
        SubjectID INT NULL CONSTRAINT FK_Attendances_Subjects FOREIGN KEY REFERENCES dbo.Subjects(SubjectID),
        AttendanceDate DATE NOT NULL,
        SlotNumber INT NULL,
        Status NVARCHAR(30) NOT NULL, -- 'PRESENT', 'EXCUSED_ABSENCE', 'UNEXCUSED_ABSENCE', 'LATE'
        Note NVARCHAR(255) NULL,
        RecordedByUserID INT NOT NULL CONSTRAINT FK_Attendances_Users FOREIGN KEY REFERENCES dbo.Users(UserID),
        CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME2 NOT NULL DEFAULT GETDATE()
    );

    CREATE UNIQUE NONCLUSTERED INDEX UQ_Attendances_Student_Session 
    ON dbo.Attendances(StudentID, AttendanceDate, SlotNumber) 
    WHERE SlotNumber IS NOT NULL;

    CREATE NONCLUSTERED INDEX IX_Attendances_Student_Date 
    ON dbo.Attendances(StudentID, AttendanceDate DESC);

    CREATE NONCLUSTERED INDEX IX_Attendances_Class_Date 
    ON dbo.Attendances(ClassID, AttendanceDate);
END
GO

-- 2. Notifications Table (In-app Notification Center)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Notifications')
BEGIN
    CREATE TABLE dbo.Notifications (
        NotificationID INT IDENTITY(1,1) PRIMARY KEY,
        UserID INT NOT NULL CONSTRAINT FK_Notifications_Users FOREIGN KEY REFERENCES dbo.Users(UserID),
        Title NVARCHAR(200) NOT NULL,
        Body NVARCHAR(1000) NOT NULL,
        Type VARCHAR(50) NOT NULL, -- 'GRADE_UPDATE', 'LEAVE_REQUEST_STATUS', 'ATTENDANCE_ALERT', 'ANNOUNCEMENT', 'SYSTEM'
        ReferenceID INT NULL,
        IsRead BIT NOT NULL DEFAULT 0,
        CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
        ReadAt DATETIME2 NULL
    );

    CREATE NONCLUSTERED INDEX IX_Notifications_User_Read 
    ON dbo.Notifications(UserID, IsRead, CreatedAt DESC);
END
GO

-- 3. UserDeviceTokens Table (FCM Token Registry)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserDeviceTokens')
BEGIN
    CREATE TABLE dbo.UserDeviceTokens (
        TokenID INT IDENTITY(1,1) PRIMARY KEY,
        UserID INT NOT NULL CONSTRAINT FK_DeviceTokens_Users FOREIGN KEY REFERENCES dbo.Users(UserID),
        DeviceToken NVARCHAR(500) NOT NULL,
        DeviceType VARCHAR(20) NOT NULL DEFAULT 'ANDROID',
        LastActiveAt DATETIME2 NOT NULL DEFAULT GETDATE(),
        CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
        CONSTRAINT UQ_User_DeviceToken UNIQUE (UserID, DeviceToken)
    );

    CREATE NONCLUSTERED INDEX IX_DeviceTokens_User 
    ON dbo.UserDeviceTokens(UserID);
END
GO
