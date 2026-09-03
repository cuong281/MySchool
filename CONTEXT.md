# MySchool - Context Analysis

## 1. Project Overview

**MySchool** la mot he thong quan ly truong hoc toan dien gom ung dung di dong danh cho hoc sinh, phu huynh, giao vien va backend REST API ket noi co so du lieu quan he. He thong so hoa toan bo cac quy trinh hoc tap: xem diem, quan ly don xin nghi hoc, xem thoi khoa bieu, cap nhat tin tuc, su kien va khen thuong / ky luat.

Du an duoc xay dung tren cac cong nghe hien dai:

- **Mobile Application**: Flutter (Dart) — ho tro da nen tang (Android, iOS, Desktop), giao dien hien dai, responsive, ho tro che do sang/toi va tuong tac muot ma.
- **Backend REST API**: Java 17, Spring Boot 3.1.5, Spring Data JPA, Hibernate, Spring Security voi ma hoa mat khau BCrypt.
- **Database Layer**: Microsoft SQL Server (`GradeDB`) — co so du lieu quan he ho tro rang buoc toan ven, foreign keys va computed persisted columns (tinh diem trung binh va GPA tu dong).
- **Automated Testing Suite**: Kien truc kiem thu 2 tang voi Node.js custom test harness cho API va `flutter_test` cho mobile unit/widget testing.


## 2. Main Goals

Muc tieu chinh cua he thong MySchool:

- **Xac thuc nguoi dung an toan**: Dang nhap bang so dien thoai, ma hoa mat khau bang BCrypt, ho tro phan quyen da vai tro (Student, Teacher, Admin).
- **Quan ly diem hoc tap minh bach**: Cung cap bang diem chi tiet theo mon hoc (chuyen can, giua ky, cuoi ky), tu dong tinh diem trung binh he 10, diem chu va GPA he 4 thong qua DB engine.
- **Quy trinh xin phep nghi hoc truc tuyen**: Hoc sinh tao don kem ly do va khoang thoi gian; he thong kiem tra tinh hop le cua ngay thang; Admin / Giao vien duyet hoac tu choi kem ghi chu va luu vet lich su (Audit History).
- **Lich hoc va thoi khoa bieu thoi gian thuc**: Hien thi thoi khoa bieu theo tung thu trong tuan, tiet hoc, phong hoc va giao vien phu trach.
- **Cong thong tin truong hoc**: Cap nhat tin tuc, thong bao khan, lich su kien sap dien ra va danh ba lien he giao vien bo mon.
- **Khen thuong & Ky luat**: Ghi nhan va cong bo quyet dinh khen thuong, ky luat cua nha truong doi voi hoc sinh.
- **Kien truc tach lop ro rang**: Backend tuan thu mo hinh Controller - Service - Repository - DTO; Mobile tuan thu mo hinh Screen - Controller - Service - Model - Singleton Session.


## 3. Users And Roles

He thong phan quyen dua tren cac vai tro (Roles):

| Vai tro | Mo ta | Quyen han & Chuc nang chinh |
|---|---|---|
| **Student (Hoc sinh)** | Nguoi dung hoc sinh dang theo hoc | - Xem thong tin ca nhan, lop hoc.<br>- Xem bang diem tat ca mon hoc, GPA.<br>- Xem thoi khoa bieu theo tuan.<br>- Tao va theo doi don xin phep nghi hoc.<br>- Xem tin tuc, su kien truong hoc.<br>- Tra cuu danh ba giao vien bo mon cua lop.<br>- Xem quyet dinh khen thuong/ky luat. |
| **Admin (Ban giam hieu / Quan tri vien)** | Quan ly toan truong | - Xem va quan ly toan bo don xin nghi cua toan truong.<br>- Duyet hoac tu choi don nghi hoc kem ghi chu.<br>- Quan ly bang diem, nhap diem, sua diem, xoa diem.<br>- Quan ly lop hoc, phan cong giao vien.<br>- Dang tin tuc, tao su kien. |
| **Teacher (Giao vien)** | Giao vien bo mon / Giao vien chu nhiem | - Xem danh sach lop giang day / chu nhiem.<br>- Nhap va cap nhat diem cho hoc sinh lop phu trach.<br>- Xem don nghi hoc cua hoc sinh trong lop.<br>- Xem thoi khoa bieu giang day. |


## 4. Core Features

### 4.1 Authentication & Session Management
- Dang nhap bang so dien thoai va mat khau.
- Mat khau duoc hash bang `BCryptPasswordEncoder` (khong luu plain text).
- Kiem tra trang thai tai khoan `IsActive = 1`.
- Sau khi dang nhap thanh cong, backend tra ve `AuthResponse` chua thong tin nguoi dung, danh sach quyen (`roles`), ma hoc sinh (`studentCode`), lop hoc (`className`, `classId`).
- Mobile luu tru phien dang nhap thong qua Singleton `UserSession` xuyen suot vong doi ung dung.

### 4.2 Grade Management (Quan ly diem)
- Quan ly diem 3 dau diem: Diem chuyen can (`AttendanceScore`), Diem giua ky (`MidtermScore`), Diem cuoi ky (`FinalScore`).
- Tu dong tinh toan bang SQL Server Computed Columns:
  - Diem trung binh: `AverageScore = (AttendanceScore * 1 + MidtermScore * 2 + FinalScore * 3) / 6.0` (lam tron 2 chu so thap phan).
  - Diem chu: `LetterGrade` (Xuat sac >= 9.0, Gioi >= 8.0, Kha >= 6.5, Trung binh >= 5.0, Yeu < 5.0).
  - Diem he 4: `GPA4` (4.0, 3.5, 3.0, 2.0, 1.0, 0.0).
- Rang buoc duy nhat (`UQ_Grades_Combo`): Mot hoc sinh chi co duy nhat 1 ban ghi diem cho moi mon hoc trong mot hoc ky cua mot nam hoc.
- REST API ho tro day du CRUD: `GET /api/grades`, `GET /api/grades/{id}`, `GET /api/grades/user/{userId}`, `GET /api/grades/class/{classId}`, `POST`, `PUT`, `DELETE`.

### 4.3 Leave Request & Workflow (Don xin phep nghi hoc)
- Hoc sinh tao don xin phep nghi hoc truc tuyen:
  - Chon loai don (`RequestType`: Nghi om, Viec gia dinh, Khac).
  - Chon tu ngay (`FromDate`) den ngay (`ToDate`).
  - Nhap ly do chi tiet (`Reason`).
- Quy tac kiem tra nghiep vu chat che:
  - `FromDate` khong duoc truoc ngay hien tai (`FromDate >= today`).
  - `ToDate` phai bang hoac sau `FromDate` (`ToDate >= FromDate`).
  - `Reason` khong duoc de trong.
- Vong doi trang thai (State Transition):
  - Khi tao: mac dinh `Chờ duyệt` (Pending).
  - Admin xu ly: Chuyen thanh `Đã duyệt` (Approved) hoac `Từ chối` (Rejected).
- Ghi vet lich su (Audit Log): Moi lan cap nhat trang thai, he thong tu dong ghi ban ghi vao bang `LeaveRequestStatusHistory` kem nguoi thay doi, trang thai cu, trang thai moi, thoi gian va ghi chu admin.

### 4.4 Timetable & Schedule (Thoi khoa bieu)
- Quan ly thoi khoa bieu theo tiet hoc (`TimeSlots` gom tiet sang va tiet chieu) va cac thu trong tuan (`DayOfWeek`: Thu 2 den Chu nhat).
- Lien ket voi mon hoc (`Subject`), lop hoc (`SchoolClass`), phong hoc (`RoomName`) va giao vien giang day (`Teacher`).
- Rang buoc xung dot (`UQ_Sched_Conflict`): Cung mot lop khong the co 2 tiet hoc trung gio trong cung mot thu.
- API ho tro lay lich hoc theo ca nhan hoc sinh (`/api/schedules/user/{userId}`) hoac theo lop (`/api/schedules/class/{classId}`).

### 4.5 Events & News (Su kien & Tin tuc)
- Su kien truong hoc: Tieu de, mo ta, thoi gian bat dau/ket thuc, dia diem, phan loai, anh banner.
- Tin tuc & Thong bao: Tieu de, noi dung day du, anh dai dien, chuyen muc, ngay dang.
- Hien thi noi bat tren trang chu Mobile kem tinh nang xem chi tiet.

### 4.6 Contact Directory (Danh ba lien he)
- Tra cuu danh sach giao vien giang day truc tiep cua hoc sinh thong qua lop hoc va phan cong chuyen mon.
- Hien thi ho ten, so dien thoai, email, mon giang day va anh dai dien de phu huynh / hoc sinh de dang ket noi khi can thiet.

### 4.7 Reward & Discipline (Khen thuong & Ky luat)
- Theo doi quyet dinh khen thuong va ky luat cua tung hoc sinh theo nam hoc va hoc ky.
- Phan loai ro rang theo nhom (`REWARD` hoac `DISCIPLINE`), so quyet dinh, noi dung chi tiet va ngay ban hanh.


## 5. Suggested Architecture

Ung dung duoc to chuc theo mo hinh da tang (Multi-Tier Architecture):

```text
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE CLIENT (Flutter)                  │
│  - Screens: Login, Home, Grades, Timetable, LeaveRequests    │
│  - Controllers & State: GradeController, RequestStore       │
│  - Services: AuthService, LeaveRequestApi, ScheduleApi,...  │
│  - Models: UserModel, Grade, ScheduleDayModel, EventModel... │
│  - Session: UserSession (Singleton)                         │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTP / JSON REST Calls
┌──────────────────────────────▼──────────────────────────────┐
│                  CONTROLLER LAYER (Spring Boot)             │
│  - AuthController, GradeController, LeaveRequestController  │
│  - ScheduleController, EventController, NewsController,...   │
│  - CrossOrigin, RequestMapping, DTO Serialization           │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                    SERVICE LAYER (Spring Boot)              │
│  - AuthService (BCrypt verify, role lookup)                 │
│  - GradeService (Duplicate validation, CRUD)                │
│  - LeaveRequestService (Date check, history logging)        │
│  - ScheduleService, EventService, NewsService,...           │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                  REPOSITORY / DAO LAYER (JPA)               │
│  - UserRepository, GradeRepository, LeaveRequestRepository  │
│  - StudentRepository, SchoolClassRepository, EventRepo...   │
│  - Spring Data JPA, Derived Queries, Native SQL             │
└──────────────────────────────┬──────────────────────────────┘
                               │ JDBC / TDS Protocol
┌──────────────────────────────▼──────────────────────────────┐
│                  DATABASE LAYER (SQL Server)                │
│  - Database: GradeDB                                        │
│  - Tables: Users, Students, Grades, LeaveRequests,...       │
│  - Computed Persisted Columns (AverageScore, LetterGrade)   │
│  - Constraints: PK, FK, Unique Combinations, Triggers       │
└─────────────────────────────────────────────────────────────┘
```


## 6. Proposed Database Schema

He thong su dung Microsoft SQL Server voi schema co ban gom cac bang chinh:

### 6.1 Users & Roles

```sql
CREATE TABLE dbo.Roles (
    RoleID          INT IDENTITY(1,1) PRIMARY KEY,
    RoleName        NVARCHAR(50) NOT NULL UNIQUE,
    Description     NVARCHAR(255) NULL,
    IsActive        BIT NOT NULL DEFAULT 1
);

CREATE TABLE dbo.Users (
    UserID          INT IDENTITY(1,1) PRIMARY KEY,
    Username        NVARCHAR(50) NOT NULL UNIQUE,
    Email           NVARCHAR(255) NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(255) NOT NULL,
    FirstName       NVARCHAR(100) NULL,
    LastName        NVARCHAR(100) NULL,
    PhoneNumber     NVARCHAR(20) NULL,
    AvatarUrl       NVARCHAR(500) NULL,
    IsActive        BIT NOT NULL DEFAULT 1,
    LastLoginAt     DATETIME2 NULL
);

CREATE TABLE dbo.User_Roles (
    UserID          INT NOT NULL,
    RoleID          INT NOT NULL,
    PRIMARY KEY (UserID, RoleID),
    CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleID) REFERENCES Roles(RoleID)
);
```

### 6.2 Students & Classes

```sql
CREATE TABLE dbo.SchoolClasses (
    ClassID         INT IDENTITY(1,1) PRIMARY KEY,
    SchoolYearID    INT NOT NULL,
    HomeroomTeacherID INT NULL,
    ClassName       NVARCHAR(50) NOT NULL,
    Status          NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
);

CREATE TABLE dbo.Students (
    StudentID       INT IDENTITY(1,1) PRIMARY KEY,
    UserID          INT NOT NULL UNIQUE,
    ClassID         INT NULL,
    StudentCode     NVARCHAR(50) NULL,
    FullName        NVARCHAR(100) NOT NULL,
    DateOfBirth     DATE NULL,
    Gender          NVARCHAR(10) NULL,
    Status          NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT FK_Students_Users FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_Students_Classes FOREIGN KEY (ClassID) REFERENCES SchoolClasses(ClassID)
);
```

### 6.3 Grades (Bang diem voi Computed Columns)

```sql
CREATE TABLE dbo.Grades (
    GradeID         INT IDENTITY(1,1) PRIMARY KEY,
    StudentID       INT NOT NULL,
    SubjectID       INT NOT NULL,
    SchoolYearID    INT NOT NULL,
    Semester        INT NOT NULL,
    AttendanceScore DECIMAL(4,2) NOT NULL DEFAULT 0,
    MidtermScore    DECIMAL(4,2) NOT NULL DEFAULT 0,
    FinalScore      DECIMAL(4,2) NOT NULL DEFAULT 0,
    
    -- Tu dong tinh diem trung binh he 10
    AverageScore AS CAST(
        ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2)
        AS DECIMAL(4,2)
    ) PERSISTED,

    -- Tu dong xep loai diem chu
    LetterGrade AS (
        CASE
            WHEN ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2) >= 9.0  THEN N'Xuat sac'
            WHEN ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2) >= 8.0  THEN N'Gioi'
            WHEN ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2) >= 6.5  THEN N'Kha'
            WHEN ROUND((AttendanceScore * 1.0 + MidtermScore * 2.0 + FinalScore * 3.0) / 6.0, 2) >= 5.0  THEN N'Trung binh'
            ELSE N'Yeu'
        END
    ) PERSISTED,

    -- Tu dong tinh GPA he 4
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

    CONSTRAINT FK_Grades_Students FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    CONSTRAINT FK_Grades_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects(SubjectID),
    CONSTRAINT FK_Grades_SchoolYears FOREIGN KEY (SchoolYearID) REFERENCES SchoolYears(SchoolYearID),
    CONSTRAINT UQ_Grades_Combo UNIQUE (StudentID, SubjectID, SchoolYearID, Semester)
);
```

### 6.4 Leave Requests & Audit History

```sql
CREATE TABLE dbo.LeaveRequests (
    RequestID       INT IDENTITY(1,1) PRIMARY KEY,
    StudentID       INT NOT NULL,
    RequestType     NVARCHAR(50) NOT NULL,
    FromDate        DATE NOT NULL,
    ToDate          DATE NOT NULL,
    Reason          NVARCHAR(1000) NOT NULL,
    Status          NVARCHAR(20) NOT NULL DEFAULT N'Chờ duyệt',
    ProcessedByUserID INT NULL,
    ProcessedAt     DATETIME2 NULL,
    AdminNote       NVARCHAR(1000) NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Leave_Students FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    CONSTRAINT FK_Leave_Admins FOREIGN KEY (ProcessedByUserID) REFERENCES Users(UserID)
);

CREATE TABLE dbo.LeaveRequestStatusHistory (
    HistoryID       INT IDENTITY(1,1) PRIMARY KEY,
    RequestID       INT NOT NULL,
    ChangedByUserID INT NOT NULL,
    OldStatus       NVARCHAR(50) NULL,
    NewStatus       NVARCHAR(50) NOT NULL,
    Note            NVARCHAR(1000) NULL,
    ChangedAt       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Hist_Requests FOREIGN KEY (RequestID) REFERENCES LeaveRequests(RequestID),
    CONSTRAINT FK_Hist_Users FOREIGN KEY (ChangedByUserID) REFERENCES Users(UserID)
);
```


## 7. Main Mobile GUI Screens

Ung dung Flutter duoc thiet ke dep mat, giao dien hien dai voi 17 man hinh tai `myfschool_mobile/lib/screens/`:

| Man hinh | File Dart | Chuc nang |
|---|---|---|
| **Login Screen** | `login.dart` | Form nhap so dien thoai, mat khau, validation, nut dang nhap, quen mat khau. |
| **Home Screen** | `homepage.dart` | Dashboard chinh: Banner chao mung, chuc nang nhanh (Diem, TKB, Don xin nghi, Tin tuc), su kien sap toi. |
| **Grade Screen** | `grade_screen.dart` | Bang diem hoc tap: GPA tong ket, loc theo hoc ky/nam hoc, the diem tung mon (CC, GK, CK, Diem chu). |
| **Timetable Screen** | `timetable_screen.dart` | Lich hoc theo tuan: Tabs chon thu 2 - thu 7, danh sach tiet hoc (gio hoc, mon hoc, giao vien, phong). |
| **Send Request Screen** | `send_request_screen.dart` | Danh sach lich su don xin nghi hoc cua hoc sinh kem trang thai (Cho duyet, Da duyet, Tu choi). |
| **Create Request Screen**| `create_request_screen.dart`| Form tao don xin phep: Chon loai nghi, DatePicker chon khoang ngay, nhap ly do chi tiet. |
| **Admin Request List** | `admin_request_list_screen.dart` | Giao dien danh cho Admin / GVCN xem toan bo don, loc theo trang thai, nut Duyet / Tu choi. |
| **Event Screen** | `event_screen.dart` | Danh sach su kien nha truong, lich hoat dong ngoai khoa, chi tiet dia diem, thoi gian. |
| **News List & Detail** | `news_list_screen.dart`<br>`news_detail_screen.dart` | Danh sach tin tuc nha truong, phan loai thong bao, bai viet chi tiet kem hinh anh. |
| **Contact List & Detail**| `contact_list_screen.dart`<br>`contact_detail_screen.dart` | Danh ba giao vien giang day cua lop, nut goi dien nhanh, gui email, thong tin phong ban. |
| **Reward & Discipline** | `reward_discipline_screen.dart` | Hien thi danh sach quyet dinh khen thuong va ky luat cua ca nhan hoc sinh. |
| **Profile & Settings** | `profilepage.dart`<br>`change_password.dart` | Thong tin tai khoan hoc sinh, ma sinh vien, lop hoc, doi mat khau, dang xuat. |


## 8. Important Business Flows

### 8.1 Flow: Dang nhap (Authentication Flow)
```text
1. Nguoi dung nhap So dien thoai va Mat khau tren man hinh Login.
2. Mobile goi POST /api/auth/login.
3. AuthService tim User theo PhoneNumber kem dieu kien IsActive = 1.
4. Neu khong tim thay: tra ve loi 401 "Sai so dien thoai hoac mat khau".
5. PasswordEncoder so khop mat khau nhap vao voi PasswordHash tu DB.
6. Neu khong khop: tra ve loi 401.
7. Neu khop:
   - Cap nhat LastLoginAt = thoi diem hien tai.
   - Lay danh sach RoleNames tu bang User_Roles.
   - Neu co role "Student", truy van them thong tin StudentCode, ClassID, ClassName.
   - Dong goi AuthResponse va tra ve HTTP 200 OK.
8. Mobile nhan AuthResponse, luu vao UserSession singleton va dieu huong vao HomePage.
```

### 8.2 Flow: Tao don xin nghi hoc (Leave Request Submission)
```text
1. Hoc sinh mo man hinh CreateRequestScreen.
2. Hoc sinh chon loai don, chon FromDate, ToDate va nhap Reason.
3. Client validate: FromDate khong duoc o qua khu, ToDate >= FromDate, Reason khong rong.
4. Mobile goi POST /api/leave-requests kem UserID.
5. Backend LeaveRequestController tiep tuc kiem tra tinh hop le cua du lieu (defense-in-depth).
6. Tim ban ghi Student ung voi UserID (neu khong co tra ve 400).
7. Tao entity LeaveRequest voi Status = "Chờ duyệt".
8. Luu vao database, tra ve HTTP 201 Created kem RequestID.
9. Mobile them don vao RequestStore va lam moi danh sach.
```

### 8.3 Flow: Duyet / Tu choi don nghi hoc (Admin Status Update)
```text
1. Admin mo man hinh AdminRequestListScreen, chon don dang "Chờ duyệt".
2. Admin chon "Duyệt" hoac "Từ chối" kem ghi chu ly do.
3. Mobile goi PATCH /api/leave-requests/{id}/status.
4. Backend mo @Transactional boundary:
   - Tim LeaveRequest theo ID (neu khong thay tra ve 404).
   - Kiem tra nguoi xu ly (ProcessedByUserId).
   - Luu OldStatus, cap nhat Status = newStatus, ProcessedAt = now(), AdminNote.
   - Luu ban ghi moi vao LeaveRequestStatusHistory de luu vet lich su.
5. Commit transaction va tra ve HTTP 200 OK kem trang thai moi.
```

### 8.4 Flow: Nhap diem mon hoc (Grade Entry Flow)
```text
1. Giao vien / Admin gui POST /api/grades kem StudentID, SubjectID, SchoolYearID, Semester, Diem CC, GK, CK.
2. GradeService kiem tra xem hoc sinh da co diem mon nay trong ky/nam nay chua:
   - Goi existsByStudentIdAndSubjectIdAndSchoolYearIdAndSemester.
   - Neu da ton tai: quang IllegalArgumentException -> Tra ve HTTP 409 Conflict.
3. Neu chua co: luu ban ghi Grade vao SQL Server.
4. SQL Server tu dong tinh toan AverageScore, LetterGrade, GPA4 nho Computed Persisted Columns.
5. Backend doc lai Grade day du kem cac cot computed va tra ve HTTP 201 Created.
```


## 9. Suggested Code Organization

### 9.1 Backend Structure (`myfschool_backend/Grade/src/main/java/com/jetbrains/grade/`)
```text
com.jetbrains.grade/
├── GradeApplication.java             # Entry point
├── config/
│   └── SecurityConfig.java           # Spring Security, CORS, CSRF disable
├── controller/                       # REST Controllers
│   ├── AuthController.java           # /api/auth/login
│   ├── GradeController.java          # /api/grades
│   ├── LeaveRequestController.java   # /api/leave-requests
│   ├── ScheduleController.java       # /api/schedules
│   ├── EventController.java          # /api/events
│   ├── NewsController.java           # /api/news
│   ├── RewardDisciplineController.java # /api/rewards-discipline
│   └── SchoolClassController.java    # /api/classes
├── dto/                              # Request / Response DTOs
│   ├── AuthResponse.java
│   ├── LoginRequest.java
│   ├── GradeDTO.java
│   ├── LeaveRequestCreateRequest.java
│   ├── LeaveRequestDTO.java
│   └── ...
├── model/                            # JPA Entities
│   ├── User.java, Role.java
│   ├── Student.java, Teacher.java
│   ├── SchoolClass.java, SchoolYear.java, Subject.java
│   ├── Grade.java
│   ├── LeaveRequest.java, LeaveRequestStatusHistory.java
│   ├── ClassSchedule.java, TimeSlot.java
│   └── Event.java, News.java, RewardDiscipline.java
├── repository/                       # Spring Data JPA Repositories
│   ├── UserRepository.java, GradeRepository.java
│   ├── LeaveRequestRepository.java, StudentRepository.java
│   └── ...
└── service/                          # Business Logic Services
    ├── AuthService.java, GradeService.java
    ├── LeaveRequestService.java, ScheduleService.java
    └── ...
```

### 9.2 Mobile Structure (`myfschool_mobile/lib/`)
```text
lib/
├── main.dart                         # Entry point, theme, initial route
├── controllers/                      # Client-side controllers
│   └── GradeController.dart          # HTTP calls for grade CRUD
├── models/                           # Data models & serialization
│   ├── user_model.dart               # User & Role mapping
│   ├── grade.dart                    # Grade model, computed columns, copyWith
│   ├── request_model.dart            # LeaveRequest & RequestStore
│   ├── schedule_model.dart           # ScheduleDayModel, SchedulePeriodModel
│   ├── event_model.dart, news_model.dart
│   ├── contact_model.dart, school_class_model.dart
│   └── reward_discipline_model.dart
├── screens/                          # UI Screens
│   ├── login.dart, homepage.dart
│   ├── grade_screen.dart, timetable_screen.dart
│   ├── create_request_screen.dart, send_request_screen.dart
│   ├── admin_request_list_screen.dart
│   ├── event_screen.dart, news_list_screen.dart, news_detail_screen.dart
│   ├── contact_list_screen.dart, contact_detail_screen.dart
│   └── profilepage.dart, reward_discipline_screen.dart
├── services/                         # API Network Layer
│   ├── auth_service.dart, user_session.dart (Singleton)
│   ├── leave_request_api.dart, schedule_api.dart
│   ├── event_service.dart, news_api.dart, contact_service.dart
│   └── reward_discipline_service.dart, school_class_api.dart
└── untils/
    └── app_color.dart                # Color tokens & theme palettes
```


## 10. Database & Technical Notes

- **Computed Columns trong SQL Server**: Bang `Grades` su dung thuoc tinh `PERSISTED` cho cac cot tinh toan (`AverageScore`, `LetterGrade`, `GPA4`). Dieu nay cho phep SQL Server tinh toan san ket qua ngay khi ghi du lieu va danh chi muc (Index) neu can, giam tai tinh toan cho backend.
- **Bao mat mat khau**: Mat khau duoc bam bang thuat toan BCrypt voi do phuc tap cao. Mat khau khong bao gio duoc tra ve trong bat ky API DTO nao.
- **DTO Mapping Pattern**: Tat ca controller khong tra ve truc tiep JPA Entities ma map thong qua cac DTO (`GradeDTO`, `LeaveRequestDTO`...) de tranh loi lazy loading, tranh vong lap vo tan (circular reference) va giu API response gon gang.
- **Quan ly Transaction**: Cac nghiep vu ghi du lieu nhieu buoc nhu duyet don xin nghi (`LeaveRequestService.updateStatus`) duoc bao boc trong `@Transactional` de dam bao tinh nguyen to (ACID).


## 11. Validation & Business Rules

1. **Authentication Rules**:
   - So dien thoai va mat khau khong duoc null hoac rong.
   - Chi cho phep nguoi dung co `IsActive = 1` dang nhap.
2. **Grade Rules**:
   - Cac dau diem (chuyen can, giua ky, cuoi ky) thuong nam trong thang diem 0.0 - 10.0.
   - Mot cap `(StudentID, SubjectID, SchoolYearID, Semester)` la duy nhat trong toan bo he thong.
3. **Leave Request Rules**:
   - `FromDate` phai tu ngay hien tai tro di (`FromDate >= CURRENT_DATE`).
   - `ToDate` phai lon hon hoac bang `FromDate`.
   - `Reason` bat buoc phai co noi dung (toi thieu 5 ky tu).
4. **Schedule Rules**:
   - Trong cung mot lop, khong duoc xep trung gio vao cung mot thu (`ClassID`, `DayOfWeek`, `TimeSlotID` la duy nhat).


## 12. Testing Strategy & QA Structure

He thong ap dung chien luoc kiem thu da tang theo tieu chuan ISTQB:

1. **API Integration Tests (`Test/automated/api-tests.mjs`)**:
   - 30 test case tu dong viet tren Node.js custom harness.
   - Kiem thu truc tiep cac HTTP Endpoint, kiem tra ma trang thai (200, 201, 400, 401, 404, 409), cau truc JSON tra ve va tinh toan ven du lieu trong database.
2. **Flutter Unit & Widget Tests (`myfschool_mobile/test/`)**:
   - 46 test case bao phu 100% cac Model (JSON parsing, fallback default values, null safety, copyWith, formatting), UserSession Singleton va khoi chay giao dien Smoke Test.
3. **Tai lieu dac ta**:
   - `01_Project_Analysis.md`: Dac ta chi tiet chuc nang, actors va phan tich rui ro.
   - `02_Test_Analysis.md`: Ap dung cac ky thuat ISTQB (Phan vung tuong duong, Phan tich gia tri bien, Bang quyet dinh, Chuyen doi trang thai).
   - `03_Test_Cases.md`: 50 test cases chi tiet voi preconditions, test steps, test data va expected results.


## 13. Possible Enhancements

- **JWT (JSON Web Token)**: Bo sung Access Token va Refresh Token de thay the session/auth thong thuong, kem co che het han token tu dong.
- **Firebase Cloud Messaging (FCM)**: Gui thong bao day (Push Notifications) den dien thoai khi don xin nghi duoc duyet hoac khi co diem moi.
- **Giao dien nhap diem danh cho giao vien**: Bo sung man hinh nhap diem hang loat cho ca lop tren Mobile / Web.
- **Upload file thuc te**: Tich hop luu tru file dinh kem (giay kham benh, don viet tay) len AWS S3 hoac Cloudinary thay vi luu local file path.
- **Parent Portal**: Bo sung tai khoan danh rieng cho phu huynh de theo doi tinh hinh hoc tap cua con em.


## 14. Main Risks & Mitigations

| Rui ro | Nguyen nhan | Giai phap khac phuc |
|---|---|---|
| **Loi ket noi tu Android Emulator** | Android Emulator khong the truy cap qua `localhost:8080` ma phai dung IP gateway `10.0.2.2:8080`. | Dat base URL la `http://10.0.2.2:8080` trong cac mobile services khi debug tren emulator; co the cau hinh dynamic qua bien moi truong. |
| **Bao mat Spring Security dang permitAll()** | `SecurityConfig` dang de `.anyRequest().permitAll()` de phuc vu phat trien va test. | Khi trien khai production, can bat JWT filter va cau hinh `@PreAuthorize("hasRole('ADMIN')")` tren cac endpoint quan tri. |
| **Xung dot duplicate ban ghi diem** | Nhap trung diem cua hoc sinh da co diem mon do trong cung hoc ky. | `GradeService` kiem tra truoc va quang loi HTTP 409 Conflict; DB co them unique index `UQ_Grades_Combo` bao ve tang sau cung. |
| **Dinh dang ngay thang giua Dart va Spring Boot** | Dart `DateTime` su dung ISO 8601 trong khi Spring Boot `LocalDate` yeu cau dinh dang `YYYY-MM-DD`. | Dinh dang ngay chuan `_formatDate` truoc khi gui trong payload va dung Jackson `LocalDateSerializer` tren backend. |
