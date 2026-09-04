-- ==========================================================
-- Migration Script: Phase 1 - Security, Authentication & JWT
-- Target: SQL Server (GradeDB)
-- Description: Idempotent script to add RefreshTokens, Teacher role,
--              Teachers.UserID column, and Teacher user accounts.
-- ==========================================================
USE GradeDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Ensure Role 'Teacher' exists in dbo.Roles
IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Teacher')
BEGIN
    SET IDENTITY_INSERT dbo.Roles ON;
    INSERT INTO dbo.Roles (RoleID, RoleName, Description)
    VALUES (3, N'Teacher', N'Giao vien');
    SET IDENTITY_INSERT dbo.Roles OFF;
    PRINT N'[Migration] Role Teacher created.';
END
ELSE
BEGIN
    PRINT N'[Migration] Role Teacher already exists.';
END
GO

-- 2. Add UserID column to dbo.Teachers if not present
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Teachers') AND name = 'UserID')
BEGIN
    ALTER TABLE dbo.Teachers ADD UserID INT NULL;
    ALTER TABLE dbo.Teachers ADD CONSTRAINT FK_Teachers_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID);
    ALTER TABLE dbo.Teachers ADD CONSTRAINT UQ_Teachers_User UNIQUE (UserID);
    PRINT N'[Migration] UserID column added to dbo.Teachers.';
END
ELSE
BEGIN
    PRINT N'[Migration] UserID column already exists in dbo.Teachers.';
END
GO

-- 3. Create dbo.RefreshTokens table if not present
IF OBJECT_ID('dbo.RefreshTokens', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.RefreshTokens (
        TokenID         BIGINT IDENTITY(1,1) PRIMARY KEY,
        UserID          INT                 NOT NULL,
        TokenHash       NVARCHAR(255)       NOT NULL UNIQUE,
        ExpiryDate      DATETIME2           NOT NULL,
        IsRevoked       BIT                 NOT NULL DEFAULT 0,
        CreatedAt       DATETIME2           NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_RefreshTokens_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID)
    );
    CREATE INDEX IX_RefreshTokens_User ON dbo.RefreshTokens(UserID);
    PRINT N'[Migration] Table dbo.RefreshTokens created.';
END
ELSE
BEGIN
    PRINT N'[Migration] Table dbo.RefreshTokens already exists.';
END
GO

-- 4. Insert 8 Teacher users if they do not exist
-- Password hash for '123456': $2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = 'teacher_han')
BEGIN
    SET IDENTITY_INSERT dbo.Users ON;
    INSERT INTO dbo.Users (UserID, Username, PasswordHash, Email, PhoneNumber, FirstName, LastName, IsActive, IsEmailVerified) VALUES
    (8,  N'teacher_han',    N'$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', N'han@myfschool.vn',            N'0901000001', N'Ngoc Han', N'Nguyen', 1, 1),
    (9,  N'teacher_hien',   N'$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', N'hien@myfschool.vn',           N'0901000002', N'Thi Hien', N'Nguyen', 1, 1),
    (10, N'teacher_duong',  N'$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', N'duong@myfschool.vn',          N'0901000003', N'Thuy Duong', N'Phan', 1, 1),
    (11, N'teacher_hong',   N'$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', N'hong@myfschool.vn',           N'0901000004', N'Thu Hong', N'Tran',   1, 1),
    (12, N'teacher_hanh',   N'$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', N'hanh@myfschool.vn',           N'0901000005', N'Duc Hanh', N'Trinh',  1, 1),
    (13, N'teacher_nam',    N'$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', N'nam@myfschool.vn',            N'0901000006', N'Hoang Nam', N'Dang',  1, 1),
    (14, N'teacher_tu',     N'$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', N'tu@myfschool.vn',             N'0901000007', N'Minh Tu', N'Vu',     1, 1),
    (15, N'teacher_trang',  N'$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', N'trang@myfschool.vn',          N'0901000008', N'Thu Trang', N'Le',    1, 1);
    SET IDENTITY_INSERT dbo.Users OFF;

    -- Assign Teacher role (RoleID = 3)
    INSERT INTO dbo.User_Roles (UserID, RoleID) VALUES
    (8, 3), (9, 3), (10, 3), (11, 3), (12, 3), (13, 3), (14, 3), (15, 3);

    -- Link Teachers to User accounts
    UPDATE dbo.Teachers SET UserID = 8  WHERE TeacherID = 1;
    UPDATE dbo.Teachers SET UserID = 9  WHERE TeacherID = 2;
    UPDATE dbo.Teachers SET UserID = 10 WHERE TeacherID = 3;
    UPDATE dbo.Teachers SET UserID = 11 WHERE TeacherID = 4;
    UPDATE dbo.Teachers SET UserID = 12 WHERE TeacherID = 5;
    UPDATE dbo.Teachers SET UserID = 13 WHERE TeacherID = 6;
    UPDATE dbo.Teachers SET UserID = 14 WHERE TeacherID = 7;
    UPDATE dbo.Teachers SET UserID = 15 WHERE TeacherID = 8;

    PRINT N'[Migration] 8 Teacher users created and linked successfully.';
END
ELSE
BEGIN
    PRINT N'[Migration] Teacher users already exist.';
END
GO

PRINT N'[Migration] Phase 1 Security migration completed successfully!';
