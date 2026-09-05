-- ==========================================================
-- Flyway Migration V3: Seed Initial Data
-- ==========================================================

-- 1. Roles
INSERT IGNORE INTO Roles (RoleID, RoleName, IsActive) VALUES
(1, 'Admin',   1),
(2, 'Student', 1),
(3, 'Teacher', 1);

-- 2. Users (Password: 123456 -> $2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi or $2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni)
INSERT IGNORE INTO Users (UserID, Username, PasswordHash, Email, PhoneNumber, FirstName, LastName, IsActive, IsEmailVerified) VALUES
(1, 'admin',           '$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi', 'admin@myfschool.vn',           '0909999999', 'Quan', 'Tri Vien', 1, 1),
(2, 'nguyenvana',      '$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi', 'nguyenvana@myfschool.vn',      '0901111111', 'Van A', 'Nguyen', 1, 1),
(3, 'tranthib',        '$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi', 'tranthib@myfschool.vn',        '0902222222', 'Thi B', 'Tran',   1, 1),
(4, 'levanc',          '$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi', 'levanc@myfschool.vn',          '0903333333', 'Van C', 'Le',     1, 1),
(5, 'phanvand',        '$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi', 'phanvand@myfschool.vn',        '0904444444', 'Van D', 'Phan',   1, 1),
(6, 'hoangthie',       '$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi', 'hoangthie@myfschool.vn',       '0905555555', 'Thi E', 'Hoang',  1, 1),
(7, 'vuminhf',         '$2a$10$AK5bksWopLL3qLAPM4c.TOhAajcj2XwOSkhvgq6ZFT7s2j21GWOKi', 'vuminhf@myfschool.vn',         '0906666666', 'Minh F', 'Vu',     1, 1),
(8,  'teacher_han',    '$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', 'han@myfschool.vn',            '0901000001', 'Ngoc Han', 'Nguyen', 1, 1),
(9,  'teacher_hien',   '$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', 'hien@myfschool.vn',           '0901000002', 'Thi Hien', 'Nguyen', 1, 1),
(10, 'teacher_duong',  '$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', 'duong@myfschool.vn',          '0901000003', 'Thuy Duong', 'Phan', 1, 1),
(11, 'teacher_hong',   '$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', 'hong@myfschool.vn',           '0901000004', 'Thu Hong', 'Tran',   1, 1),
(12, 'teacher_hanh',   '$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', 'hanh@myfschool.vn',           '0901000005', 'Duc Hanh', 'Trinh',  1, 1),
(13, 'teacher_nam',    '$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', 'nam@myfschool.vn',            '0901000006', 'Hoang Nam', 'Dang',  1, 1),
(14, 'teacher_tu',     '$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', 'tu@myfschool.vn',             '0901000007', 'Minh Tu', 'Vu',     1, 1),
(15, 'teacher_trang',  '$2a$10$qqXH1T2MnQcPuURCFBSh2e3pk7.BoQe.q919/4FpnDCqhXm7UOnni', 'trang@myfschool.vn',          '0901000008', 'Thu Trang', 'Le',    1, 1);

-- 3. User_Roles
INSERT IGNORE INTO User_Roles (UserID, RoleID) VALUES
(1, 1), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2),
(8, 3), (9, 3), (10, 3), (11, 3), (12, 3), (13, 3), (14, 3), (15, 3);

-- 4. Teachers
INSERT IGNORE INTO Teachers (TeacherID, UserID, FullName, Email, PhoneNumber, Status) VALUES
(1, 8,  'Nguyen Ngoc Han', 'han@myfschool.vn',   '0901000001', 'ACTIVE'),
(2, 9,  'Nguyen Thi Hien', 'hien@myfschool.vn',  '0901000002', 'ACTIVE'),
(3, 10, 'Phan Thuy Duong', 'duong@myfschool.vn', '0901000003', 'ACTIVE'),
(4, 11, 'Tran Thu Hong',   'hong@myfschool.vn',  '0901000004', 'ACTIVE'),
(5, 12, 'Trinh Duc Hanh',  'hanh@myfschool.vn',  '0901000005', 'ACTIVE'),
(6, 13, 'Dang Hoang Nam',  'nam@myfschool.vn',   '0901000006', 'ACTIVE'),
(7, 14, 'Vu Minh Tu',      'tu@myfschool.vn',    '0901000007', 'ACTIVE'),
(8, 15, 'Le Thu Trang',    'trang@myfschool.vn', '0901000008', 'ACTIVE');

-- 5. Subjects
INSERT IGNORE INTO Subjects (SubjectID, SubjectCode, SubjectName, IsActive) VALUES
(1, 'MATH', 'Toan', 1),
(2, 'LIT', 'Ngu van', 1),
(3, 'ENG', 'Tieng Anh', 1),
(4, 'ICT', 'Tin hoc va Cong nghe', 1),
(5, 'VOV', 'Vovinam', 1),
(6, 'STEM', 'STEM', 1),
(7, 'PE', 'Giao duc the chat', 1),
(8, 'PHY', 'Vat ly', 1),
(9, 'CHE', 'Hoa hoc', 1),
(10, 'BIO', 'Sinh hoc', 1);

-- 6. School Years
INSERT IGNORE INTO SchoolYears (SchoolYearID, YearName, StartDate, EndDate, IsActive) VALUES
(1, '2025-2026', '2025-08-15', '2026-05-31', 1),
(2, '2026-2027', '2026-08-15', '2027-05-31', 0);

-- 7. School Classes
INSERT IGNORE INTO SchoolClasses (ClassID, SchoolYearID, HomeroomTeacherID, ClassName, Status) VALUES
(1, 1, 1, '10A1', 'ACTIVE'),
(2, 1, 2, '10A2', 'ACTIVE');

-- 8. Students
INSERT IGNORE INTO Students (StudentID, UserID, ClassID, StudentCode, FullName, Status) VALUES
(1, 2, 1, 'HS2025001', 'Nguyen Van A', 'ACTIVE'),
(2, 3, 1, 'HS2025002', 'Tran Thi B',   'ACTIVE'),
(3, 4, 1, 'HS2025003', 'Le Van C',     'ACTIVE'),
(4, 5, 2, 'HS2025004', 'Phan Van D',   'ACTIVE'),
(5, 6, 2, 'HS2025005', 'Hoang Thi E',  'ACTIVE'),
(6, 7, 2, 'HS2025006', 'Vu Minh F',    'ACTIVE');

-- 9. Time Slots
INSERT IGNORE INTO TimeSlots (TimeSlotID, SlotNumber, StartTime, EndTime, SessionType, IsActive) VALUES
(1, 1, '07:00:00', '07:45:00', 'MORNING', 1),
(2, 2, '07:55:00', '08:40:00', 'MORNING', 1),
(3, 3, '08:50:00', '09:35:00', 'MORNING', 1),
(4, 4, '09:45:00', '10:30:00', 'MORNING', 1),
(5, 5, '13:00:00', '13:45:00', 'AFTERNOON', 1),
(6, 6, '13:55:00', '14:40:00', 'AFTERNOON', 1),
(7, 7, '14:50:00', '15:35:00', 'AFTERNOON', 1),
(8, 8, '15:45:00', '16:30:00', 'AFTERNOON', 1);

-- 10. Files
INSERT IGNORE INTO Files (FileID, UploadedByUserID, FileName, FileUrl, FileType, FileSize) VALUES
(1, 1, 'banner.jpg', '/uploads/events/banner.jpg', 'image/jpeg', 204800),
(2, 1, 'proof.pdf', '/uploads/leave/proof.pdf', 'application/pdf', 102400);

-- 11. Grades (Semester 1 & 2)
INSERT IGNORE INTO Grades (StudentID, SubjectID, SchoolYearID, Semester, AttendanceScore, MidtermScore, FinalScore) VALUES
(1, 1, 1, 1, 9.0, 8.0, 8.5),
(1, 4, 1, 1, 10.0, 9.5, 9.0),
(1, 5, 1, 1, 8.5, 8.0, 9.0),
(2, 1, 1, 1, 8.0, 7.5, 8.0),
(2, 4, 1, 1, 8.5, 8.0, 8.0),
(3, 2, 1, 1, 7.0, 7.5, 7.0),
(4, 1, 1, 1, 9.5, 9.0, 9.5),
(4, 2, 1, 1, 8.5, 8.0, 9.0),
(4, 3, 1, 1, 9.0, 9.0, 8.5),
(5, 1, 1, 1, 5.0, 4.5, 5.5),
(5, 2, 1, 1, 4.5, 5.0, 4.0),
(5, 3, 1, 1, 5.5, 5.0, 5.0),
(6, 1, 1, 1, 7.5, 7.0, 7.5),
(6, 2, 1, 1, 7.0, 8.0, 7.5),

(1, 1, 1, 2, 8.5, 8.5, 9.0),
(1, 4, 1, 2, 9.5, 9.0, 9.5),
(1, 5, 1, 2, 9.0, 8.5, 8.5),
(2, 1, 1, 2, 7.5, 8.0, 8.5),
(2, 4, 1, 2, 8.0, 8.5, 9.0),
(3, 2, 1, 2, 8.0, 7.0, 8.0),
(4, 1, 1, 2, 9.5, 9.5, 10.0),
(4, 2, 1, 2, 9.0, 8.5, 9.5),
(4, 3, 1, 2, 9.5, 9.0, 9.0),
(5, 1, 1, 2, 5.5, 6.0, 5.0),
(5, 2, 1, 2, 6.0, 6.5, 6.0),
(5, 3, 1, 2, 5.0, 5.0, 5.5),
(6, 1, 1, 2, 8.0, 8.5, 8.0),
(6, 2, 1, 2, 7.5, 8.0, 8.5);

-- 12. Teacher Assignments
INSERT IGNORE INTO TeacherAssignments (TeacherID, SubjectID, ClassID, RoleType) VALUES
(1, 1, 1, 'HOMEROOM_TEACHER'),
(1, 1, 1, 'SUBJECT_TEACHER'),
(1, 1, 2, 'SUBJECT_TEACHER'),
(2, 2, 1, 'SUBJECT_TEACHER'),
(2, 2, 2, 'HOMEROOM_TEACHER'),
(2, 2, 2, 'SUBJECT_TEACHER'),
(3, 3, 1, 'SUBJECT_TEACHER'),
(4, 4, 1, 'SUBJECT_TEACHER'),
(4, 6, 1, 'SUBJECT_TEACHER'),
(5, 8, 1, 'SUBJECT_TEACHER'),
(6, 9, 1, 'SUBJECT_TEACHER'),
(7, 10, 1, 'SUBJECT_TEACHER'),
(7, 5, 1, 'SUBJECT_TEACHER'),
(8, 7, 1, 'SUBJECT_TEACHER');

-- 13. Class Schedules
INSERT IGNORE INTO ClassSchedules (ClassID, DayOfWeek, TimeSlotID, SubjectID, TeacherID, RoomName, Status) VALUES
-- MONDAY
(1, 'MONDAY', 1, 1, 1, 'P101', 'ACTIVE'),
(1, 'MONDAY', 2, 2, 2, 'P101', 'ACTIVE'),
(1, 'MONDAY', 3, 3, 3, 'P101', 'ACTIVE'),
(1, 'MONDAY', 4, 8, 5, 'P101', 'ACTIVE'),
(1, 'MONDAY', 5, 9, 6, 'P101', 'ACTIVE'),
(1, 'MONDAY', 6, 4, 4, 'Lab1', 'ACTIVE'),
(1, 'MONDAY', 7, 7, 8, 'Gym', 'ACTIVE'),
(1, 'MONDAY', 8, 5, 7, 'Hall', 'ACTIVE'),

(2, 'MONDAY', 1, 7, 8, 'Gym', 'ACTIVE'),
(2, 'MONDAY', 2, 5, 7, 'Hall', 'ACTIVE'),
(2, 'MONDAY', 3, 1, 1, 'P102', 'ACTIVE'),
(2, 'MONDAY', 4, 2, 2, 'P102', 'ACTIVE'),
(2, 'MONDAY', 5, 3, 3, 'P102', 'ACTIVE'),
(2, 'MONDAY', 6, 8, 5, 'P102', 'ACTIVE'),
(2, 'MONDAY', 7, 9, 6, 'P102', 'ACTIVE'),
(2, 'MONDAY', 8, 4, 4, 'Lab2', 'ACTIVE'),

-- TUESDAY
(1, 'TUESDAY', 1, 1, 1, 'P101', 'ACTIVE'),
(1, 'TUESDAY', 2, 2, 2, 'P101', 'ACTIVE'),
(1, 'TUESDAY', 3, 3, 3, 'P101', 'ACTIVE'),
(1, 'TUESDAY', 4, 10, 7, 'P101', 'ACTIVE'),
(1, 'TUESDAY', 5, 6, 4, 'P101', 'ACTIVE'),
(1, 'TUESDAY', 6, 9, 6, 'P101', 'ACTIVE'),
(1, 'TUESDAY', 7, 1, 1, 'P101', 'ACTIVE'),
(1, 'TUESDAY', 8, 5, 7, 'Hall', 'ACTIVE'),

(2, 'TUESDAY', 1, 1, 1, 'P102', 'ACTIVE'),
(2, 'TUESDAY', 2, 5, 7, 'Hall', 'ACTIVE'),
(2, 'TUESDAY', 3, 1, 1, 'P102', 'ACTIVE'),
(2, 'TUESDAY', 4, 2, 2, 'P102', 'ACTIVE'),
(2, 'TUESDAY', 5, 3, 3, 'P102', 'ACTIVE'),
(2, 'TUESDAY', 6, 10, 7, 'P102', 'ACTIVE'),
(2, 'TUESDAY', 7, 6, 4, 'P102', 'ACTIVE'),
(2, 'TUESDAY', 8, 9, 6, 'P102', 'ACTIVE'),

-- WEDNESDAY
(1, 'WEDNESDAY', 1, 2, 2, 'P101', 'ACTIVE'),
(1, 'WEDNESDAY', 2, 3, 3, 'P101', 'ACTIVE'),
(1, 'WEDNESDAY', 3, 8, 5, 'P101', 'ACTIVE'),
(1, 'WEDNESDAY', 4, 4, 4, 'Lab1', 'ACTIVE'),
(1, 'WEDNESDAY', 5, 10, 7, 'P101', 'ACTIVE'),
(1, 'WEDNESDAY', 6, 1, 1, 'P101', 'ACTIVE'),
(1, 'WEDNESDAY', 7, 7, 8, 'Gym', 'ACTIVE'),
(1, 'WEDNESDAY', 8, 6, 4, 'P101', 'ACTIVE'),

(2, 'WEDNESDAY', 1, 7, 8, 'Gym', 'ACTIVE'),
(2, 'WEDNESDAY', 2, 6, 4, 'P102', 'ACTIVE'),
(2, 'WEDNESDAY', 3, 2, 2, 'P102', 'ACTIVE'),
(2, 'WEDNESDAY', 4, 3, 3, 'P102', 'ACTIVE'),
(2, 'WEDNESDAY', 5, 8, 5, 'P102', 'ACTIVE'),
(2, 'WEDNESDAY', 6, 4, 4, 'Lab2', 'ACTIVE'),
(2, 'WEDNESDAY', 7, 10, 7, 'P102', 'ACTIVE'),
(2, 'WEDNESDAY', 8, 1, 1, 'P102', 'ACTIVE'),

-- THURSDAY
(1, 'THURSDAY', 1, 1, 1, 'P101', 'ACTIVE'),
(1, 'THURSDAY', 2, 2, 2, 'P101', 'ACTIVE'),
(1, 'THURSDAY', 3, 3, 3, 'P101', 'ACTIVE'),
(1, 'THURSDAY', 4, 9, 6, 'P101', 'ACTIVE'),
(1, 'THURSDAY', 5, 10, 7, 'P101', 'ACTIVE'),
(1, 'THURSDAY', 6, 8, 5, 'P101', 'ACTIVE'),
(1, 'THURSDAY', 7, 5, 7, 'Hall', 'ACTIVE'),
(1, 'THURSDAY', 8, 4, 4, 'Lab1', 'ACTIVE'),

(2, 'THURSDAY', 1, 5, 7, 'Hall', 'ACTIVE'),
(2, 'THURSDAY', 2, 4, 4, 'Lab2', 'ACTIVE'),
(2, 'THURSDAY', 3, 1, 1, 'P102', 'ACTIVE'),
(2, 'THURSDAY', 4, 2, 2, 'P102', 'ACTIVE'),
(2, 'THURSDAY', 5, 3, 3, 'P102', 'ACTIVE'),
(2, 'THURSDAY', 6, 9, 6, 'P102', 'ACTIVE'),
(2, 'THURSDAY', 7, 10, 7, 'P102', 'ACTIVE'),
(2, 'THURSDAY', 8, 8, 5, 'P102', 'ACTIVE'),

-- FRIDAY
(1, 'FRIDAY', 1, 1, 1, 'P101', 'ACTIVE'),
(1, 'FRIDAY', 2, 2, 2, 'P101', 'ACTIVE'),
(1, 'FRIDAY', 3, 3, 3, 'P101', 'ACTIVE'),
(1, 'FRIDAY', 4, 8, 5, 'P101', 'ACTIVE'),
(1, 'FRIDAY', 5, 9, 6, 'P101', 'ACTIVE'),
(1, 'FRIDAY', 6, 10, 7, 'P101', 'ACTIVE'),
(1, 'FRIDAY', 7, 7, 8, 'Gym', 'ACTIVE'),
(1, 'FRIDAY', 8, 6, 4, 'P101', 'ACTIVE'),

(2, 'FRIDAY', 1, 7, 8, 'Gym', 'ACTIVE'),
(2, 'FRIDAY', 2, 6, 4, 'P102', 'ACTIVE'),
(2, 'FRIDAY', 3, 1, 1, 'P102', 'ACTIVE'),
(2, 'FRIDAY', 4, 2, 2, 'P102', 'ACTIVE'),
(2, 'FRIDAY', 5, 3, 3, 'P102', 'ACTIVE'),
(2, 'FRIDAY', 6, 8, 5, 'P102', 'ACTIVE'),
(2, 'FRIDAY', 7, 9, 6, 'P102', 'ACTIVE'),
(2, 'FRIDAY', 8, 10, 7, 'P102', 'ACTIVE');

-- 14. Leave Requests
INSERT IGNORE INTO LeaveRequests (RequestID, StudentID, RequestType, FromDate, ToDate, Reason, Status, AttachmentFileID) VALUES
(1, 1, 'Xin nghi hoc', '2026-03-20', '2026-03-20', 'Sot nhe', 'Chờ duyệt', 2),
(2, 2, 'Xin nghi hoc', '2026-03-15', '2026-03-16', 'Ve que', 'Đã duyệt', NULL);

-- 15. Reward Discipline Types
INSERT IGNORE INTO RewardDisciplineTypes (TypeID, TypeCode, TypeName, GroupName, IsActive) VALUES
(1, 'REWARD_EXCELLENT', 'Học tập xuất sắc', 'Khen thưởng', 1),
(2, 'REWARD_ACTIVITY', 'Tham gia hoạt động tốt', 'Khen thưởng', 1),
(3, 'DISCIPLINE_LATE', 'Di học muộn', 'Kỷ luật', 1),
(4, 'DISCIPLINE_UNIFORM', 'Vi phạm đồng phục', 'Kỷ luật', 1);

-- 16. Reward Disciplines
INSERT IGNORE INTO RewardDisciplines (StudentID, TypeID, SchoolYearID, Semester, DecisionNumber, Content, IssuedByUserID, IssuedDate) VALUES
(1, 1, 1, 1, 'QD-001', 'Học sinh xuất sắc học kỳ 1 năm học 2025-2026', 1, '2026-01-10'),
(1, 2, 1, 1, 'QD-002', 'Đạt giải Nhất cuộc thi Sáng tạo STEM cấp trường', 1, '2026-02-20'),
(1, 3, 1, 2, 'QD-003', 'Đi học muộn 3 lần trong cùng một tuần', 1, '2026-03-15'),
(1, 4, 1, 2, 'QD-004', 'Không mặc đúng đồng phục khi đến trường', 1, '2026-03-18'),
(4, 1, 1, 1, 'QD-005', 'Học sinh tiêu biểu có thành tích học tập tốt nhất lớp 10A2', 1, '2026-03-19'),
(5, 3, 1, 1, 'QD-006', 'Cảnh cáo kết quả học tập yếu (Điểm trung bình các môn dưới 5.0)', 1, '2026-03-19'),
(5, 3, 1, 1, 'QD-007', 'Nghỉ học không phép 2 lần trong học kỳ 1', 1, '2026-02-10'),
(6, 2, 1, 1, 'QD-008', 'Nhiệt tình tham gia phong trào văn nghệ chào mừng 26/03', 1, '2026-03-19');

-- 17. Events
INSERT IGNORE INTO Events (Title, Description, StartAt, EndAt, Location, Category, Status, CreatedByUserID) VALUES
('Lễ khai mạc Tuần lễ văn hóa 2026', 'Chuỗi hoạt động giao lưu văn hóa nghệ thuật và ẩm thực học đường', DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 3 DAY), INTERVAL 8 HOUR), DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 3 DAY), INTERVAL 11 HOUR), 'Sân vận động', 'CULTURE', 'Đã kết thúc', 1),
('Giải bóng đá F-School Cup - Vòng bảng', 'Các trận cầu sôi nổi tranh vé vào bán kết giữa khối 10 và khối 11', DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 2 DAY), INTERVAL 15*60 + 30 MINUTE), DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 2 DAY), INTERVAL 17*60 + 30 MINUTE), 'Sân bóng đá FPT', 'SPORTS', 'Đã kết thúc', 1),
('Hội thảo Kỹ năng phòng chống bạo lực học đường', 'Chuyên đề kỹ năng sống và văn hóa ứng xử văn minh trong môi trường học đường', DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 1 DAY), INTERVAL 14 HOUR), DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 1 DAY), INTERVAL 16*60 + 30 MINUTE), 'Hội trường Tòa Alpha', 'SEMINAR', 'Đã kết thúc', 1),

('Seminar Hướng nghiệp và Phát triển bản thân', 'Định hướng nghề nghiệp và xu hướng công nghệ tương lai cùng các diễn giả hàng đầu', DATE_ADD(CURDATE(), INTERVAL 8 HOUR), DATE_ADD(CURDATE(), INTERVAL 11*60 + 30 MINUTE), 'Hội trường A', 'SEMINAR', 'Đang diễn ra', 1),
('Triển lãm Dự án Khoa học & Công nghệ K10', 'Trưng bày và chấm điểm các sản phẩm sáng tạo STEM và robot thông minh', DATE_ADD(CURDATE(), INTERVAL 13*60 + 30 MINUTE), DATE_ADD(CURDATE(), INTERVAL 16*60 + 30 MINUTE), 'Sảnh tòa nhà Innovation', 'STEM', 'Đang diễn ra', 1),
('Đêm nhạc Acoustic "Giai điệu Mùa thu"', 'Không gian âm nhạc giao lưu sôi động của các câu lạc bộ nghệ thuật F-School', DATE_ADD(CURDATE(), INTERVAL 18*60 + 30 MINUTE), DATE_ADD(CURDATE(), INTERVAL 21 HOUR), 'Khuôn viên Đài phun nước', 'MUSIC', 'Đang diễn ra', 1),

('Ngày hội STEM & Robotics 2026', 'Khám phá không gian khoa học, thi đấu Robocon và thực tế ảo VR', DATE_ADD(DATE_ADD(CURDATE(), INTERVAL 1 DAY), INTERVAL 8 HOUR), DATE_ADD(DATE_ADD(CURDATE(), INTERVAL 1 DAY), INTERVAL 12 HOUR), 'Sân trường chính', 'STEM', 'Sắp tới', 1),
('Chung kết Cuộc thi Hùng biện tiếng Anh F-Speaker', 'Vòng tranh tài hùng biện và tranh biện tiếng Anh của các thí sinh xuất sắc nhất', DATE_ADD(DATE_ADD(CURDATE(), INTERVAL 3 DAY), INTERVAL 8*60 + 30 MINUTE), DATE_ADD(DATE_ADD(CURDATE(), INTERVAL 3 DAY), INTERVAL 11*60 + 30 MINUTE), 'Hội trường lớn Gamma', 'COMPETITION', 'Sắp tới', 1),
('Hội thao FPT School 2026 - Lễ Bế mạc & Trao giải', 'Lễ bế mạc trao huy chương và cúp vô địch các môn bóng đá, bóng rổ, cầu lông', DATE_ADD(DATE_ADD(CURDATE(), INTERVAL 7 DAY), INTERVAL 14 HOUR), DATE_ADD(DATE_ADD(CURDATE(), INTERVAL 7 DAY), INTERVAL 17 HOUR), 'Nhà thi đấu đa năng', 'SPORTS', 'Sắp tới', 1);

-- 18. News
INSERT IGNORE INTO News (Title, Content, ImageUrl, Category, PublishedDate, IsActive) VALUES
('THÔNG BÁO LỊCH NGHỈ LỄ GIỖ TỔ HÙNG VƯƠNG, 30/04 VÀ 01/05', 
 'P.TC&QLĐT TB V/V NGHỈ LỄ GIỖ TỔ HÙNG VƯƠNG, NGÀY CHIẾN THẮNG 30/04 VÀ NGÀY QUỐC TẾ LAO ĐỘNG 2023.\n\nThời gian nghỉ: Từ 29/04 đến hết 03/05.\nNgày quay lại trường: 04/05.', 
 'https://cdn.vietnammoi.vn/1881912202208777/images/2024/4/10/hinh-anh-ve-gio-to-hung-vuong-4-20240410113339987.jpg?width=700', 'Thông báo', '2026-03-20 08:00:00', 1),

('PHÁT ĐỘNG GIẢI CHẠY ỦNG HỘ XÂY TRƯỜNG VÙNG CAO - FSCHOOLS ORANGE DAY', 
 'Giải chạy vì cộng đồng nhằm gây quỹ xây dựng trường học cho trẻ em vùng cao khó khăn. Mọi sự đóng góp của PH và Học sinh đều quý giá.', 
 'https://tse3.mm.bing.net/th/id/OIP.CLR_BeSgPosZqyszuZZK3gHaJ_?rs=1&pid=ImgDetMain&o=7&rm=3', 'Sự kiện', '2026-03-19 09:00:00', 1),

('THÔNG BÁO VỀ VIỆC KHÔNG BIẾU TẶNG QUÀ TẾT', 
 'Kính gửi Quý Phụ huynh, các em học sinh, sinh viên Tổ chức giáo dục FPT. Nhằm duy trì nếp sống giản dị và tôn trọng văn hóa sư phạm...', 
 'https://school.fpt.edu.vn/uploads/tet_notice.jpg', 'Thông báo', '2026-03-18 14:00:00', 1);
