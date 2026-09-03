USE GradeDB;
GO

SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET QUOTED_IDENTIFIER ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

-- =============================================
-- Xoa bang cu theo thu tu phu thuoc (Reverse Order)
-- =============================================
IF OBJECT_ID('dbo.Events', 'U') IS NOT NULL DROP TABLE dbo.Events;
IF OBJECT_ID('dbo.News', 'U') IS NOT NULL DROP TABLE dbo.News;
IF OBJECT_ID('dbo.RewardDisciplines', 'U') IS NOT NULL DROP TABLE dbo.RewardDisciplines;
IF OBJECT_ID('dbo.RewardDisciplineTypes', 'U') IS NOT NULL DROP TABLE dbo.RewardDisciplineTypes;
IF OBJECT_ID('dbo.LeaveRequestStatusHistory', 'U') IS NOT NULL DROP TABLE dbo.LeaveRequestStatusHistory;
IF OBJECT_ID('dbo.LeaveRequests', 'U') IS NOT NULL DROP TABLE dbo.LeaveRequests;
IF OBJECT_ID('dbo.Grades', 'U') IS NOT NULL DROP TABLE dbo.Grades;
IF OBJECT_ID('dbo.ClassSchedules', 'U') IS NOT NULL DROP TABLE dbo.ClassSchedules;
IF OBJECT_ID('dbo.TeacherAssignments', 'U') IS NOT NULL DROP TABLE dbo.TeacherAssignments;
IF OBJECT_ID('dbo.Students', 'U') IS NOT NULL DROP TABLE dbo.Students;
IF OBJECT_ID('dbo.SchoolClasses', 'U') IS NOT NULL DROP TABLE dbo.SchoolClasses;
IF OBJECT_ID('dbo.TimeSlots', 'U') IS NOT NULL DROP TABLE dbo.TimeSlots;
IF OBJECT_ID('dbo.Subjects', 'U') IS NOT NULL DROP TABLE dbo.Subjects;
IF OBJECT_ID('dbo.SchoolYears', 'U') IS NOT NULL DROP TABLE dbo.SchoolYears;
IF OBJECT_ID('dbo.Teachers', 'U') IS NOT NULL DROP TABLE dbo.Teachers;
IF OBJECT_ID('dbo.Files', 'U') IS NOT NULL DROP TABLE dbo.Files;
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL DROP TABLE dbo.Users;
IF OBJECT_ID('dbo.Roles', 'U') IS NOT NULL DROP TABLE dbo.Roles;
GO

-- =============================================
-- 1. Roles & Users
-- =============================================
CREATE TABLE dbo.Roles (
    RoleID          INT IDENTITY(1,1)   PRIMARY KEY,
    RoleName        NVARCHAR(50)        NOT NULL UNIQUE,
    Description     NVARCHAR(255)       NULL,
    IsActive        BIT                 NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE dbo.Users (
    UserID          INT IDENTITY(1,1)   PRIMARY KEY,
    Username        NVARCHAR(50)        NOT NULL UNIQUE,
    Email           NVARCHAR(255)       NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(255)       NOT NULL,
    FirstName       NVARCHAR(100)       NULL,
    LastName        NVARCHAR(100)       NULL,
    PhoneNumber     NVARCHAR(20)        NULL,
    AvatarUrl       NVARCHAR(500)       NULL,
    IsActive        BIT                 NOT NULL DEFAULT 1,
    IsEmailVerified BIT                 NOT NULL DEFAULT 0,
    LastLoginAt     DATETIME2           NULL,
    CreatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE dbo.User_Roles (
    UserID          INT                 NOT NULL,
    RoleID          INT                 NOT NULL,
    PRIMARY KEY (UserID, RoleID),
    CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleID) REFERENCES Roles(RoleID)
);

-- =============================================
-- 2. Files & Infrastructure
-- =============================================
CREATE TABLE dbo.Files (
    FileID          INT IDENTITY(1,1)   PRIMARY KEY,
    UploadedByUserID INT                NULL,
    FileName        NVARCHAR(255)       NOT NULL,
    FileUrl         NVARCHAR(500)       NOT NULL,
    FileType        NVARCHAR(50)        NULL,
    FileSize        BIGINT              NULL,
    CreatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Files_Users FOREIGN KEY (UploadedByUserID) REFERENCES Users(UserID)
);

CREATE TABLE dbo.Teachers (
    TeacherID       INT IDENTITY(1,1)   PRIMARY KEY,
    FullName        NVARCHAR(100)       NOT NULL,
    Email           NVARCHAR(255)       NULL,
    PhoneNumber     NVARCHAR(20)        NULL,
    AvatarUrl       NVARCHAR(500)       NULL,
    Status          NVARCHAR(20)        NOT NULL DEFAULT 'ACTIVE'
);

CREATE TABLE dbo.Subjects (
    SubjectID       INT IDENTITY(1,1)   PRIMARY KEY,
    SubjectCode     NVARCHAR(20)        NOT NULL UNIQUE,
    SubjectName     NVARCHAR(100)       NOT NULL,
    IsActive        BIT                 NOT NULL DEFAULT 1
);

CREATE TABLE dbo.SchoolYears (
    SchoolYearID    INT IDENTITY(1,1)   PRIMARY KEY,
    YearName        NVARCHAR(20)        NOT NULL,
    StartDate       DATE                NULL,
    EndDate         DATE                NULL,
    IsActive        BIT                 NOT NULL DEFAULT 1
);

CREATE TABLE dbo.TimeSlots (
    TimeSlotID      INT IDENTITY(1,1)   PRIMARY KEY,
    SlotNumber      INT                 NOT NULL,
    StartTime       TIME                NOT NULL,
    EndTime         TIME                NOT NULL,
    SessionType     NVARCHAR(20)        NOT NULL, -- MORNING, AFTERNOON
    IsActive        BIT                 NOT NULL DEFAULT 1
);

-- =============================================
-- 3. Classes & Students
-- =============================================
CREATE TABLE dbo.SchoolClasses (
    ClassID         INT IDENTITY(1,1)   PRIMARY KEY,
    SchoolYearID    INT                 NOT NULL,
    HomeroomTeacherID INT               NULL,
    ClassName       NVARCHAR(50)        NOT NULL,
    Status          NVARCHAR(20)        NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT FK_Classes_Years FOREIGN KEY (SchoolYearID) REFERENCES SchoolYears(SchoolYearID),
    CONSTRAINT FK_Classes_Teachers FOREIGN KEY (HomeroomTeacherID) REFERENCES Teachers(TeacherID)
);

CREATE TABLE dbo.Students (
    StudentID       INT IDENTITY(1,1)   PRIMARY KEY,
    UserID          INT                 NOT NULL UNIQUE,
    ClassID         INT                 NULL,
    StudentCode     NVARCHAR(50)        NULL,
    FullName        NVARCHAR(100)       NOT NULL,
    DateOfBirth     DATE                NULL,
    Gender          NVARCHAR(10)        NULL,
    Address         NVARCHAR(255)       NULL,
    ParentName      NVARCHAR(100)       NULL,
    ParentPhone     NVARCHAR(20)        NULL,
    Status          NVARCHAR(20)        NOT NULL DEFAULT 'ACTIVE',
    CreatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Students_Users FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_Students_Classes FOREIGN KEY (ClassID) REFERENCES SchoolClasses(ClassID)
);

-- =============================================
-- 4. Assignments & Schedules
-- =============================================
CREATE TABLE dbo.TeacherAssignments (
    AssignmentID    INT IDENTITY(1,1)   PRIMARY KEY,
    TeacherID       INT                 NOT NULL,
    SubjectID       INT                 NULL,
    ClassID         INT                 NOT NULL,
    RoleType        NVARCHAR(50)        NOT NULL, -- SUBJECT_TEACHER, HOMEROOM_TEACHER
    CONSTRAINT FK_Assign_Teachers FOREIGN KEY (TeacherID) REFERENCES Teachers(TeacherID),
    CONSTRAINT FK_Assign_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects(SubjectID),
    CONSTRAINT FK_Assign_Classes FOREIGN KEY (ClassID) REFERENCES SchoolClasses(ClassID)
);

CREATE TABLE dbo.ClassSchedules (
    ScheduleID      INT IDENTITY(1,1)   PRIMARY KEY,
    ClassID         INT                 NOT NULL,
    DayOfWeek       NVARCHAR(20)        NOT NULL,
    TimeSlotID      INT                 NOT NULL,
    SubjectID       INT                 NOT NULL,
    TeacherID       INT                 NOT NULL,
    RoomName        NVARCHAR(50)        NULL,
    Status          NVARCHAR(20)        NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT FK_Sched_Classes FOREIGN KEY (ClassID) REFERENCES SchoolClasses(ClassID),
    CONSTRAINT FK_Sched_Slots FOREIGN KEY (TimeSlotID) REFERENCES TimeSlots(TimeSlotID),
    CONSTRAINT FK_Sched_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects(SubjectID),
    CONSTRAINT FK_Sched_Teachers FOREIGN KEY (TeacherID) REFERENCES Teachers(TeacherID),
    CONSTRAINT UQ_Sched_Conflict UNIQUE (ClassID, DayOfWeek, TimeSlotID)
);

-- =============================================
-- 5. Grades (CONNECTED MODULE)
-- =============================================
CREATE TABLE dbo.Grades (
    GradeID         INT IDENTITY(1,1)   PRIMARY KEY,
    StudentID       INT                 NOT NULL,
    SubjectID       INT                 NOT NULL,
    SchoolYearID    INT                 NOT NULL,
    Semester        INT                 NOT NULL,
    AttendanceScore DECIMAL(4,2)        NOT NULL DEFAULT 0,
    MidtermScore    DECIMAL(4,2)        NOT NULL DEFAULT 0,
    FinalScore      DECIMAL(4,2)        NOT NULL DEFAULT 0,
    
    -- Computed columns
    AverageScore AS CAST(
        ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2)
        AS DECIMAL(4,2)
    ) PERSISTED,

    LetterGrade AS (
        CASE
            WHEN ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2) >= 9.0  THEN N'Xuat sac'
            WHEN ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2) >= 8.0  THEN N'Gioi'
            WHEN ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2) >= 6.5  THEN N'Kha'
            WHEN ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2) >= 5.0  THEN N'Trung binh'
            ELSE N'Yeu'
        END
    ) PERSISTED,

    GPA4 AS CAST(
        CASE
            WHEN ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2) >= 9.0  THEN 4.0
            WHEN ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2) >= 8.0  THEN 3.5
            WHEN ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2) >= 6.5  THEN 3.0
            WHEN ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2) >= 5.0  THEN 2.0
            WHEN ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2) >= 3.5  THEN 1.0
            ELSE 0.0
        END
        AS DECIMAL(3,1)
    ) PERSISTED,

    CreatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
    
    CONSTRAINT FK_Grades_Students FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    CONSTRAINT FK_Grades_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects(SubjectID),
    CONSTRAINT FK_Grades_SchoolYears FOREIGN KEY (SchoolYearID) REFERENCES SchoolYears(SchoolYearID),
    CONSTRAINT UQ_Grades_Combo UNIQUE (StudentID, SubjectID, SchoolYearID, Semester)
);

-- =============================================
-- 6. Leave Requests
-- =============================================
CREATE TABLE dbo.LeaveRequests (
    RequestID       INT IDENTITY(1,1)   PRIMARY KEY,
    StudentID       INT                 NOT NULL,
    RequestType     NVARCHAR(50)        NOT NULL,
    FromDate        DATE                NOT NULL,
    ToDate          DATE                NOT NULL,
    Reason          NVARCHAR(1000)      NOT NULL,
    Status          NVARCHAR(20)        NOT NULL DEFAULT N'Chờ duyệt',
    AttachmentFileID INT                NULL,
    ProcessedByUserID INT               NULL,
    ProcessedAt     DATETIME2           NULL,
    AdminNote       NVARCHAR(1000)      NULL,
    CreatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Leave_Students FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    CONSTRAINT FK_Leave_Files FOREIGN KEY (AttachmentFileID) REFERENCES Files(FileID),
    CONSTRAINT FK_Leave_Admins FOREIGN KEY (ProcessedByUserID) REFERENCES Users(UserID)
);

CREATE TABLE dbo.LeaveRequestStatusHistory (
    HistoryID       INT IDENTITY(1,1)   PRIMARY KEY,
    RequestID       INT                 NOT NULL,
    ChangedByUserID INT                 NOT NULL,
    OldStatus       NVARCHAR(50)        NULL,
    NewStatus       NVARCHAR(50)        NOT NULL,
    Note            NVARCHAR(1000)      NULL,
    ChangedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Hist_Requests FOREIGN KEY (RequestID) REFERENCES LeaveRequests(RequestID),
    CONSTRAINT FK_Hist_Users FOREIGN KEY (ChangedByUserID) REFERENCES Users(UserID)
);

-- =============================================
-- 7. Reward & Discipline
-- =============================================
CREATE TABLE dbo.RewardDisciplineTypes (
    TypeID          INT IDENTITY(1,1)   PRIMARY KEY,
    TypeCode        NVARCHAR(50)        NOT NULL UNIQUE,
    TypeName        NVARCHAR(100)       NOT NULL,
    GroupName       NVARCHAR(50)        NOT NULL, -- REWARD, DISCIPLINE
    IsActive        BIT                 NOT NULL DEFAULT 1
);

CREATE TABLE dbo.RewardDisciplines (
    RecordID        INT IDENTITY(1,1)   PRIMARY KEY,
    StudentID       INT                 NOT NULL,
    TypeID          INT                 NOT NULL,
    SchoolYearID    INT                 NOT NULL,
    Semester        INT                 NULL,
    DecisionNumber  NVARCHAR(50)        NULL,
    Content         NVARCHAR(1000)      NULL,
    IssuedByUserID  INT                 NULL,
    IssuedDate      DATE                NOT NULL,
    FileID          INT                 NULL,
    CreatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_RD_Students FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    CONSTRAINT FK_RD_Types FOREIGN KEY (TypeID) REFERENCES RewardDisciplineTypes(TypeID),
    CONSTRAINT FK_RD_Years FOREIGN KEY (SchoolYearID) REFERENCES SchoolYears(SchoolYearID),
    CONSTRAINT FK_RD_Issuers FOREIGN KEY (IssuedByUserID) REFERENCES Users(UserID),
    CONSTRAINT FK_RD_Files FOREIGN KEY (FileID) REFERENCES Files(FileID)
);

-- =============================================
-- 8. Events
-- =============================================
CREATE TABLE dbo.Events (
    EventID         INT IDENTITY(1,1)   PRIMARY KEY,
    Title           NVARCHAR(200)       NOT NULL,
    Description     NVARCHAR(1000)      NULL,
    StartAt         DATETIME2           NULL,
    EndAt           DATETIME2           NULL,
    Location        NVARCHAR(255)       NULL,
    Category        NVARCHAR(50)        NULL,
    Status          NVARCHAR(50)        NULL,
    BannerFileID    INT                 NULL,
    CreatedByUserID INT                 NULL,
    CONSTRAINT FK_Events_Files FOREIGN KEY (BannerFileID) REFERENCES Files(FileID),
    CONSTRAINT FK_Events_Users FOREIGN KEY (CreatedByUserID) REFERENCES Users(UserID)
);

-- =============================================
-- 9. News
-- =============================================
CREATE TABLE dbo.News (
    NewsID          INT IDENTITY(1,1)   PRIMARY KEY,
    Title           NVARCHAR(255)       NOT NULL,
    Content         NVARCHAR(MAX)       NULL,
    ImageUrl        NVARCHAR(500)       NULL,
    Category        NVARCHAR(100)       NULL,
    PublishedDate   DATETIME2           NULL,
    IsActive        BIT                 NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

PRINT N'Database schema created successfully!';
