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

/* 1. Xoa du lieu theo thu tu phu thuoc (Reverse Order) */
DELETE FROM dbo.Events;
DELETE FROM dbo.RewardDisciplines;
DELETE FROM dbo.News;
DELETE FROM dbo.RewardDisciplineTypes;
DELETE FROM dbo.LeaveRequestStatusHistory;
DELETE FROM dbo.LeaveRequests;
DELETE FROM dbo.Grades;
DELETE FROM dbo.ClassSchedules;
DELETE FROM dbo.TeacherAssignments;
DELETE FROM dbo.Students;
DELETE FROM dbo.TimeSlots;
DELETE FROM dbo.SchoolClasses;
DELETE FROM dbo.Subjects;
DELETE FROM dbo.Teachers;
DELETE FROM dbo.SchoolYears;
DELETE FROM dbo.Files;
DELETE FROM dbo.User_Roles;
DELETE FROM dbo.Users;
DELETE FROM dbo.Roles;
GO

/* 2. Reseed identity de an toan */
DBCC CHECKIDENT ('dbo.Events', RESEED, 0);
DBCC CHECKIDENT ('dbo.RewardDisciplines', RESEED, 0);
DBCC CHECKIDENT ('dbo.News', RESEED, 0);
DBCC CHECKIDENT ('dbo.RewardDisciplineTypes', RESEED, 0);
DBCC CHECKIDENT ('dbo.LeaveRequestStatusHistory', RESEED, 0);
DBCC CHECKIDENT ('dbo.LeaveRequests', RESEED, 0);
DBCC CHECKIDENT ('dbo.Grades', RESEED, 0);
DBCC CHECKIDENT ('dbo.ClassSchedules', RESEED, 0);
DBCC CHECKIDENT ('dbo.TeacherAssignments', RESEED, 0);
DBCC CHECKIDENT ('dbo.Students', RESEED, 0);
DBCC CHECKIDENT ('dbo.TimeSlots', RESEED, 0);
DBCC CHECKIDENT ('dbo.SchoolClasses', RESEED, 0);
DBCC CHECKIDENT ('dbo.Subjects', RESEED, 0);
DBCC CHECKIDENT ('dbo.Teachers', RESEED, 0);
DBCC CHECKIDENT ('dbo.SchoolYears', RESEED, 0);
DBCC CHECKIDENT ('dbo.Files', RESEED, 0);
DBCC CHECKIDENT ('dbo.Users', RESEED, 0);
DBCC CHECKIDENT ('dbo.Roles', RESEED, 0);
GO

/* 3. Roles */
SET IDENTITY_INSERT dbo.Roles ON;
INSERT INTO dbo.Roles (RoleID, RoleName, Description) VALUES
(1, N'Admin',      N'Quan tri vien he thong'),
(2, N'Student',    N'Hoc sinh');
SET IDENTITY_INSERT dbo.Roles OFF;
GO

/* 4. Users (Admin, Student accounts) */
SET IDENTITY_INSERT dbo.Users ON;
INSERT INTO dbo.Users (UserID, Username, PasswordHash, Email, PhoneNumber, FirstName, LastName, IsActive, IsEmailVerified) VALUES
(1, N'admin',      N'$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi', N'admin@myfschool.vn',      N'0909999999', N'Quan', N'Tri Vien', 1, 1),
(2, N'nguyenvana', N'$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi', N'nguyenvana@myfschool.vn', N'0901111111', N'Van A', N'Nguyen', 1, 1),
(3, N'tranthib',   N'$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi', N'tranthib@myfschool.vn',   N'0902222222', N'Thi B', N'Tran',   1, 1),
(4, N'levanc',     N'$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi', N'levanc@myfschool.vn',     N'0903333333', N'Van C', N'Le',     1, 1),
(5, N'phanvand',   N'$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi', N'phanvand@myfschool.vn',   N'0904444444', N'Van D', N'Phan',   1, 1),
(6, N'hoangthie',  N'$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi', N'hoangthie@myfschool.vn',  N'0905555555', N'Thi E', N'Hoang',  1, 1),
(7, N'vuminhf',    N'$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi', N'vuminhf@myfschool.vn',    N'0906666666', N'Minh F', N'Vu',     1, 1);
SET IDENTITY_INSERT dbo.Users OFF;
GO

/* 4b. User_Roles (Junction) */
INSERT INTO dbo.User_Roles (UserID, RoleID) VALUES
(1, 1), -- Admin
(2, 2), -- Student A
(3, 2), -- Student B
(4, 2), -- Student C
(5, 2), -- Student D
(6, 2), -- Student E
(7, 2); -- Student F
GO

/* 5. Teachers */
SET IDENTITY_INSERT dbo.Teachers ON;
INSERT INTO dbo.Teachers (TeacherID, FullName, Email, PhoneNumber, Status) VALUES
(1, N'Nguyen Ngoc Han', 'han@myfschool.vn', '0901000001', N'ACTIVE'),
(2, N'Nguyen Thi Hien', 'hien@myfschool.vn', '0901000002', N'ACTIVE'),
(3, N'Phan Thuy Duong', 'duong@myfschool.vn', '0901000003', N'ACTIVE'),
(4, N'Tran Thu Hong', 'hong@myfschool.vn', '0901000004', N'ACTIVE'),
(5, N'Trinh Duc Hanh', 'hanh@myfschool.vn', '0901000005', N'ACTIVE'),
(6, N'Dang Hoang Nam', 'nam@myfschool.vn', '0901000006', N'ACTIVE'),
(7, N'Vu Minh Tu', 'tu@myfschool.vn', '0901000007', N'ACTIVE'),
(8, N'Le Thu Trang', 'trang@myfschool.vn', '0901000008', N'ACTIVE');
SET IDENTITY_INSERT dbo.Teachers OFF;
GO

/* 6. Subjects */
SET IDENTITY_INSERT dbo.Subjects ON;
INSERT INTO dbo.Subjects (SubjectID, SubjectCode, SubjectName, IsActive) VALUES
(1, N'MATH', N'Toan', 1),
(2, N'LIT', N'Ngu van', 1),
(3, N'ENG', N'Tieng Anh', 1),
(4, N'ICT', N'Tin hoc va Cong nghe', 1),
(5, N'VOV', N'Vovinam', 1),
(6, N'STEM', N'STEM', 1),
(7, N'PE', N'Giao duc the chat', 1),
(8, N'PHY', N'Vat ly', 1),
(9, N'CHE', N'Hoa hoc', 1),
(10, N'BIO', N'Sinh hoc', 1);
SET IDENTITY_INSERT dbo.Subjects OFF;
GO

/* 7. School Years */
SET IDENTITY_INSERT dbo.SchoolYears ON;
INSERT INTO dbo.SchoolYears (SchoolYearID, YearName, StartDate, EndDate, IsActive) VALUES
(1, N'2025-2026', '2025-08-15', '2026-05-31', 1),
(2, N'2026-2027', '2026-08-15', '2027-05-31', 0);
SET IDENTITY_INSERT dbo.SchoolYears OFF;
GO

/* 8. School Classes */
SET IDENTITY_INSERT dbo.SchoolClasses ON;
INSERT INTO dbo.SchoolClasses (ClassID, SchoolYearID, HomeroomTeacherID, ClassName, Status) VALUES
(1, 1, 1, N'10A1', N'ACTIVE'),
(2, 1, 2, N'10A2', N'ACTIVE');
SET IDENTITY_INSERT dbo.SchoolClasses OFF;
GO

/* 9. Students */
SET IDENTITY_INSERT dbo.Students ON;
INSERT INTO dbo.Students (StudentID, UserID, ClassID, StudentCode, FullName, Status) VALUES
(1, 2, 1, N'HS2025001', N'Nguyen Van A', N'ACTIVE'),
(2, 3, 1, N'HS2025002', N'Tran Thi B',   N'ACTIVE'),
(3, 4, 1, N'HS2025003', N'Le Van C',     N'ACTIVE'),
(4, 5, 2, N'HS2025004', N'Phan Van D',   N'ACTIVE'),
(5, 6, 2, N'HS2025005', N'Hoang Thi E',  N'ACTIVE'),
(6, 7, 2, N'HS2025006', N'Vu Minh F',    N'ACTIVE');
SET IDENTITY_INSERT dbo.Students OFF;
GO

/* 10. Time Slots */
SET IDENTITY_INSERT dbo.TimeSlots ON;
INSERT INTO dbo.TimeSlots (TimeSlotID, SlotNumber, StartTime, EndTime, SessionType, IsActive) VALUES
(1, 1, '07:00:00', '07:45:00', N'MORNING', 1),
(2, 2, '07:55:00', '08:40:00', N'MORNING', 1),
(3, 3, '08:50:00', '09:35:00', N'MORNING', 1),
(4, 4, '09:45:00', '10:30:00', N'MORNING', 1),
(5, 5, '13:00:00', '13:45:00', N'AFTERNOON', 1),
(6, 6, '13:55:00', '14:40:00', N'AFTERNOON', 1),
(7, 7, '14:50:00', '15:35:00', N'AFTERNOON', 1),
(8, 8, '15:45:00', '16:30:00', N'AFTERNOON', 1);
SET IDENTITY_INSERT dbo.TimeSlots OFF;
GO

/* 11. Files */
SET IDENTITY_INSERT dbo.Files ON;
INSERT INTO dbo.Files (FileID, UploadedByUserID, FileName, FileUrl, FileType, FileSize) VALUES
(1, 1, N'banner.jpg', N'/uploads/events/banner.jpg', N'image/jpeg', 204800),
(2, 1, N'proof.pdf', N'/uploads/leave/proof.pdf', N'application/pdf', 102400);
SET IDENTITY_INSERT dbo.Files OFF;
GO

/* 12. Grades (Detail tables are safe to auto-gen if parent IDs are fixed) */
-- Semester 1
INSERT INTO dbo.Grades (StudentID, SubjectID, SchoolYearID, Semester, AttendanceScore, MidtermScore, FinalScore) VALUES
(1, 1, 1, 1, 9.0, 8.0, 8.5),
(1, 4, 1, 1, 10.0, 9.5, 9.0),
(1, 5, 1, 1, 8.5, 8.0, 9.0),
(2, 1, 1, 1, 8.0, 7.5, 8.0),
(2, 4, 1, 1, 8.5, 8.0, 8.0),
(3, 2, 1, 1, 7.0, 7.5, 7.0),

-- New Students 10A2 - Semester 1
(4, 1, 1, 1, 9.5, 9.0, 9.5), -- Phan Van D: Toán
(4, 2, 1, 1, 8.5, 8.0, 9.0), -- Phan Van D: Văn
(4, 3, 1, 1, 9.0, 9.0, 8.5), -- Phan Van D: Anh
(5, 1, 1, 1, 5.0, 4.5, 5.5), -- Hoang Thi E: Toán (TB ~ 4.9)
(5, 2, 1, 1, 4.5, 5.0, 4.0), -- Hoang Thi E: Văn (TB ~ 4.3)
(5, 3, 1, 1, 5.5, 5.0, 5.0), -- Hoang Thi E: Anh (TB ~ 5.1)
(6, 1, 1, 1, 7.5, 7.0, 7.5), -- Vu Minh F: Toán
(6, 2, 1, 1, 7.0, 8.0, 7.5); -- Vu Minh F: Văn

-- Semester 2
INSERT INTO dbo.Grades (StudentID, SubjectID, SchoolYearID, Semester, AttendanceScore, MidtermScore, FinalScore) VALUES
(1, 1, 1, 2, 8.5, 8.5, 9.0),
(1, 4, 1, 2, 9.5, 9.0, 9.5),
(1, 5, 1, 2, 9.0, 8.5, 8.5),
(2, 1, 1, 2, 7.5, 8.0, 8.5),
(2, 4, 1, 2, 8.0, 8.5, 9.0),
(3, 2, 1, 2, 8.0, 7.0, 8.0),

-- New Students 10A2 - Semester 2
(4, 1, 1, 2, 9.5, 9.5, 10.0), -- Phan Van D: Toán
(4, 2, 1, 2, 9.0, 8.5, 9.5),  -- Phan Van D: Văn
(4, 3, 1, 2, 9.5, 9.0, 9.0),  -- Phan Van D: Anh
(5, 1, 1, 2, 5.5, 6.0, 5.0),  -- Hoang Thi E: Toán (TB ~ 5.4 - Tiến bộ)
(5, 2, 1, 2, 6.0, 6.5, 6.0),  -- Hoang Thi E: Văn (TB ~ 6.1)
(5, 3, 1, 2, 5.0, 5.0, 5.5),  -- Hoang Thi E: Anh (TB ~ 5.1)
(6, 1, 1, 2, 8.0, 8.5, 8.0),  -- Vu Minh F: Toán
(6, 2, 1, 2, 7.5, 8.0, 8.5);  -- Vu Minh F: Văn
GO

/* 13. Teacher Assignments (Updated as per design) */
INSERT INTO dbo.TeacherAssignments (TeacherID, SubjectID, ClassID, RoleType) VALUES
(1, 1, 1, N'HOMEROOM_TEACHER'), -- Hân: Toán + GVCN
(1, 1, 1, N'SUBJECT_TEACHER'),
(2, 2, 1, N'SUBJECT_TEACHER'),  -- Hiền: Ngữ văn
(3, 3, 1, N'SUBJECT_TEACHER'),  -- Dương: Tiếng Anh
(4, 4, 1, N'SUBJECT_TEACHER'),  -- Hồng: ICT
(4, 6, 1, N'SUBJECT_TEACHER'),  -- Hồng: STEM
(5, 8, 1, N'SUBJECT_TEACHER'),  -- Hạnh: Vật lý
(6, 9, 1, N'SUBJECT_TEACHER'),  -- Nam: Hóa học
(7, 10, 1, N'SUBJECT_TEACHER'), -- Tú: Sinh học
(7, 5, 1, N'SUBJECT_TEACHER'),  -- Tú: VOV
(8, 7, 1, N'SUBJECT_TEACHER');  -- Trang: GDTC
GO

/* 14. Class Schedules (Full 40-period week for Class 10A1) */
INSERT INTO dbo.ClassSchedules (ClassID, DayOfWeek, TimeSlotID, SubjectID, TeacherID, RoomName, Status) VALUES
-- MONDAY (Thứ 2)
(1, N'MONDAY', 1, 1, 1, N'P101', N'ACTIVE'), -- Toán
(1, N'MONDAY', 2, 2, 2, N'P101', N'ACTIVE'), -- Văn
(1, N'MONDAY', 3, 3, 3, N'P101', N'ACTIVE'), -- Anh
(1, N'MONDAY', 4, 8, 5, N'P101', N'ACTIVE'), -- Lý
(1, N'MONDAY', 5, 9, 6, N'P101', N'ACTIVE'), -- Hóa
(1, N'MONDAY', 6, 4, 4, N'Lab1', N'ACTIVE'), -- Tin
(1, N'MONDAY', 7, 7, 8, N'Gym', N'ACTIVE'),  -- Thể chất
(1, N'MONDAY', 8, 5, 7, N'Hall', N'ACTIVE'), -- VOV

(2, N'MONDAY', 1, 7, 8, N'Gym', N'ACTIVE'),  -- Thể chất
(2, N'MONDAY', 2, 5, 7, N'Hall', N'ACTIVE'), -- VOV
(2, N'MONDAY', 3, 1, 1, N'P102', N'ACTIVE'), -- Toán
(2, N'MONDAY', 4, 2, 2, N'P102', N'ACTIVE'), -- Văn
(2, N'MONDAY', 5, 3, 3, N'P102', N'ACTIVE'), -- Anh
(2, N'MONDAY', 6, 8, 5, N'P102', N'ACTIVE'), -- Lý
(2, N'MONDAY', 7, 9, 6, N'P102', N'ACTIVE'), -- Hóa
(2, N'MONDAY', 8, 4, 4, N'Lab2', N'ACTIVE'), -- Tin

-- TUESDAY (Thứ 3)
(1, N'TUESDAY', 1, 1, 1, N'P101', N'ACTIVE'), -- Toán
(1, N'TUESDAY', 2, 2, 2, N'P101', N'ACTIVE'), -- Văn
(1, N'TUESDAY', 3, 3, 3, N'P101', N'ACTIVE'), -- Anh
(1, N'TUESDAY', 4, 10, 7, N'P101', N'ACTIVE'),-- Sinh
(1, N'TUESDAY', 5, 6, 4, N'P101', N'ACTIVE'), -- STEM
(1, N'TUESDAY', 6, 9, 6, N'P101', N'ACTIVE'), -- Hóa
(1, N'TUESDAY', 7, 1, 1, N'P101', N'ACTIVE'), -- Toán
(1, N'TUESDAY', 8, 5, 7, N'Hall', N'ACTIVE'), -- VOV

(2, N'TUESDAY', 1, 1, 1, N'P102', N'ACTIVE'), -- Toán
(2, N'TUESDAY', 2, 5, 7, N'Hall', N'ACTIVE'), -- VOV
(2, N'TUESDAY', 3, 1, 1, N'P102', N'ACTIVE'), -- Toán
(2, N'TUESDAY', 4, 2, 2, N'P102', N'ACTIVE'), -- Văn
(2, N'TUESDAY', 5, 3, 3, N'P102', N'ACTIVE'), -- Anh
(2, N'TUESDAY', 6, 10, 7, N'P102', N'ACTIVE'),-- Sinh
(2, N'TUESDAY', 7, 6, 4, N'P102', N'ACTIVE'), -- STEM
(2, N'TUESDAY', 8, 9, 6, N'P102', N'ACTIVE'), -- Hóa

-- WEDNESDAY (Thứ 4)
(1, N'WEDNESDAY', 1, 2, 2, N'P101', N'ACTIVE'), -- Văn
(1, N'WEDNESDAY', 2, 3, 3, N'P101', N'ACTIVE'), -- Anh
(1, N'WEDNESDAY', 3, 8, 5, N'P101', N'ACTIVE'), -- Lý
(1, N'WEDNESDAY', 4, 4, 4, N'Lab1', N'ACTIVE'), -- Tin
(1, N'WEDNESDAY', 5, 10, 7, N'P101', N'ACTIVE'),-- Sinh
(1, N'WEDNESDAY', 6, 1, 1, N'P101', N'ACTIVE'), -- Toán
(1, N'WEDNESDAY', 7, 7, 8, N'Gym', N'ACTIVE'),  -- Thể chất
(1, N'WEDNESDAY', 8, 6, 4, N'P101', N'ACTIVE'), -- STEM

(2, N'WEDNESDAY', 1, 7, 8, N'Gym', N'ACTIVE'),  -- Thể chất
(2, N'WEDNESDAY', 2, 6, 4, N'P102', N'ACTIVE'), -- STEM
(2, N'WEDNESDAY', 3, 2, 2, N'P102', N'ACTIVE'), -- Văn
(2, N'WEDNESDAY', 4, 3, 3, N'P102', N'ACTIVE'), -- Anh
(2, N'WEDNESDAY', 5, 8, 5, N'P102', N'ACTIVE'), -- Lý
(2, N'WEDNESDAY', 6, 4, 4, N'Lab2', N'ACTIVE'), -- Tin
(2, N'WEDNESDAY', 7, 10, 7, N'P102', N'ACTIVE'),-- Sinh
(2, N'WEDNESDAY', 8, 1, 1, N'P102', N'ACTIVE'), -- Toán

-- THURSDAY (Thứ 5)
(1, N'THURSDAY', 1, 1, 1, N'P101', N'ACTIVE'), -- Toán
(1, N'THURSDAY', 2, 2, 2, N'P101', N'ACTIVE'), -- Văn
(1, N'THURSDAY', 3, 3, 3, N'P101', N'ACTIVE'), -- Anh
(1, N'THURSDAY', 4, 9, 6, N'P101', N'ACTIVE'), -- Hóa
(1, N'THURSDAY', 5, 10, 7, N'P101', N'ACTIVE'),-- Sinh
(1, N'THURSDAY', 6, 8, 5, N'P101', N'ACTIVE'), -- Lý
(1, N'THURSDAY', 7, 5, 7, N'Hall', N'ACTIVE'), -- VOV
(1, N'THURSDAY', 8, 4, 4, N'Lab1', N'ACTIVE'), -- Tin

(2, N'THURSDAY', 1, 5, 7, N'Hall', N'ACTIVE'), -- VOV
(2, N'THURSDAY', 2, 4, 4, N'Lab2', N'ACTIVE'), -- Tin
(2, N'THURSDAY', 3, 1, 1, N'P102', N'ACTIVE'), -- Toán
(2, N'THURSDAY', 4, 2, 2, N'P102', N'ACTIVE'), -- Văn
(2, N'THURSDAY', 5, 3, 3, N'P102', N'ACTIVE'), -- Anh
(2, N'THURSDAY', 6, 9, 6, N'P102', N'ACTIVE'), -- Hóa
(2, N'THURSDAY', 7, 10, 7, N'P102', N'ACTIVE'),-- Sinh
(2, N'THURSDAY', 8, 8, 5, N'P102', N'ACTIVE'), -- Lý

-- FRIDAY (Thứ 6)
(1, N'FRIDAY', 1, 1, 1, N'P101', N'ACTIVE'), -- Toán
(1, N'FRIDAY', 2, 2, 2, N'P101', N'ACTIVE'), -- Văn
(1, N'FRIDAY', 3, 3, 3, N'P101', N'ACTIVE'), -- Anh
(1, N'FRIDAY', 4, 8, 5, N'P101', N'ACTIVE'), -- Lý
(1, N'FRIDAY', 5, 9, 6, N'P101', N'ACTIVE'), -- Hóa
(1, N'FRIDAY', 6, 10, 7, N'P101', N'ACTIVE'),-- Sinh
(1, N'FRIDAY', 7, 7, 8, N'Gym', N'ACTIVE'),  -- Thể chất
(1, N'FRIDAY', 8, 6, 4, N'P101', N'ACTIVE'), -- STEM

(2, N'FRIDAY', 1, 7, 8, N'Gym', N'ACTIVE'),  -- Thể chất
(2, N'FRIDAY', 2, 6, 4, N'P102', N'ACTIVE'), -- STEM
(2, N'FRIDAY', 3, 1, 1, N'P102', N'ACTIVE'), -- Toán
(2, N'FRIDAY', 4, 2, 2, N'P102', N'ACTIVE'), -- Văn
(2, N'FRIDAY', 5, 3, 3, N'P102', N'ACTIVE'), -- Anh
(2, N'FRIDAY', 6, 8, 5, N'P102', N'ACTIVE'), -- Lý
(2, N'FRIDAY', 7, 9, 6, N'P102', N'ACTIVE'), -- Hóa
(2, N'FRIDAY', 8, 10, 7, N'P102', N'ACTIVE');-- Sinh
GO

/* 15. Leave Requests */
SET IDENTITY_INSERT dbo.LeaveRequests ON;
INSERT INTO dbo.LeaveRequests (RequestID, StudentID, RequestType, FromDate, ToDate, Reason, Status, AttachmentFileID) VALUES
(1, 1, N'Xin nghi hoc', '2026-03-20', '2026-03-20', N'Sot nhe', N'Chờ duyệt', 2),
(2, 2, N'Xin nghi hoc', '2026-03-15', '2026-03-16', N'Ve que', N'Đã duyệt', NULL);
SET IDENTITY_INSERT dbo.LeaveRequests OFF;
GO

/* 16. Reward Discipline Types */
SET IDENTITY_INSERT dbo.RewardDisciplineTypes ON;
INSERT INTO dbo.RewardDisciplineTypes (TypeID, TypeCode, TypeName, GroupName, IsActive) VALUES
(1, N'REWARD_EXCELLENT', N'Học tập xuất sắc', N'Khen thưởng', 1),
(2, N'REWARD_ACTIVITY', N'Tham gia hoạt động tốt', N'Khen thưởng', 1),
(3, N'DISCIPLINE_LATE', N'Di học muộn', N'Kỷ luật', 1),
(4, N'DISCIPLINE_UNIFORM', N'Vi phạm đồng phục', N'Kỷ luật', 1);
SET IDENTITY_INSERT dbo.RewardDisciplineTypes OFF;
GO

/* 17. Reward Disciplines */
INSERT INTO dbo.RewardDisciplines (StudentID, TypeID, SchoolYearID, Semester, DecisionNumber, Content, IssuedByUserID, IssuedDate) VALUES
(1, 1, 1, 1, N'QD-001', N'Học sinh xuất sắc học kỳ 1 năm học 2025-2026', 1, '2026-01-10'),
(1, 2, 1, 1, N'QD-002', N'Đạt giải Nhất cuộc thi Sáng tạo STEM cấp trường', 1, '2026-02-20'),
(1, 3, 1, 2, N'QD-003', N'Đi học muộn 3 lần trong cùng một tuần', 1, '2026-03-15'),
(1, 4, 1, 2, N'QD-004', N'Không mặc đúng đồng phục khi đến trường', 1, '2026-03-18'),

-- Data cho học sinh mới lớp 10A2
(4, 1, 1, 1, N'QD-005', N'Học sinh tiêu biểu có thành tích học tập tốt nhất lớp 10A2', 1, '2026-03-19'),
(5, 3, 1, 1, N'QD-006', N'Cảnh cáo kết quả học tập yếu (Điểm trung bình các môn dưới 5.0)', 1, '2026-03-19'),
(5, 3, 1, 1, N'QD-007', N'Nghỉ học không phép 2 lần trong học kỳ 1', 1, '2026-02-10'),
(6, 2, 1, 1, N'QD-008', N'Nhiệt tình tham gia phong trào văn nghệ chào mừng 26/03', 1, '2026-03-19');
GO

/* 18. Events */
INSERT INTO dbo.Events (Title, Description, StartAt, EndAt, Location, Category, Status, CreatedByUserID) VALUES
-- Sắp tới (Upcoming)
(N'Ngay hoi STEM 2026', N'STEM k10 - Kham pha khoa hoc', '2026-03-25T08:00:00', '2026-03-25T11:30:00', N'San truong', N'STEM', N'Sắp tới', 1),

-- Đang diễn ra (Ongoing)
(N'Seminar Huong nghiep', N'Buoi chia se kinh nghiem chon nganh nghe.', '2026-03-19T18:00:00', '2026-03-19T21:00:00', N'Hoi truong A', N'SEMINAR', N'Đang diễn ra', 1),

-- Đã kết thúc (Finished)
(N'Le khai mac Tuan le van hoa', N'Hoat dong van nghe khai mac.', '2026-03-18T08:00:00', '2026-03-18T10:00:00', N'San van dong', N'CULTURE', N'Đã kết thúc', 1);
GO

/* 19. News */
INSERT INTO dbo.News (Title, Content, ImageUrl, Category, PublishedDate, IsActive) VALUES
(N'THÔNG BÁO LỊCH NGHỈ LỄ GIỖ TỔ HÙNG VƯƠNG, 30/04 VÀ 01/05', 
 N'P.TC&QLĐT TB V/V NGHỈ LỄ GIỖ TỔ HÙNG VƯƠNG, NGÀY CHIẾN THẮNG 30/04 VÀ NGÀY QUỐC TẾ LAO ĐỘNG 2023.\n\nThời gian nghỉ: Từ 29/04 đến hết 03/05.\nNgày quay lại trường: 04/05.', 
 N'https://cdn.vietnammoi.vn/1881912202208777/images/2024/4/10/hinh-anh-ve-gio-to-hung-vuong-4-20240410113339987.jpg?width=700', N'Thông báo', '2026-03-20T08:00:00', 1),

(N'PHÁT ĐỘNG GIẢI CHẠY ỦNG HỘ XÂY TRƯỜNG VÙNG CAO - FSCHOOLS ORANGE DAY', 
 N'Giải chạy vì cộng đồng nhằm gây quỹ xây dựng trường học cho trẻ em vùng cao khó khăn. Mọi sự đóng góp của PH và Học sinh đều quý giá.', 
 N'https://tse3.mm.bing.net/th/id/OIP.CLR_BeSgPosZqyszuZZK3gHaJ_?rs=1&pid=ImgDetMain&o=7&rm=3', N'Sự kiện', '2026-03-19T09:00:00', 1),

(N'THÔNG BÁO VỀ VIỆC KHÔNG BIẾU TẶNG QUÀ TẾT', 
 N'Kính gửi Quý Phụ huynh, các em học sinh, sinh viên Tổ chức giáo dục FPT. Nhằm duy trì nếp sống giản dị và tôn trọng văn hóa sư phạm...', 
 N'https://school.fpt.edu.vn/uploads/tet_notice.jpg', N'Thông báo', '2026-03-18T14:00:00', 1);
GO

PRINT N'Data seeding completed successfully with explicit IDs!';
