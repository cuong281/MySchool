# MySchool - He Thong Quan Ly Truong Hoc

Du an gom 3 phan rieng:

- `myfschool_backend/Grade/`: Java Spring Boot 3.1.5 REST API, ket noi SQL Server bang Spring Data JPA va Hibernate.
- `myfschool_mobile/`: Flutter (Dart) mobile application danh cho hoc sinh va nha truong, ket noi REST API.
- `Test/`: Bo kiem thu tu dong (Node.js API test harness + Flutter unit tests + tai lieu dac ta ISTQB).


## Database

Database mac dinh tren SQL Server:

```text
GradeDB
```

File tao schema va du lieu demo nam trong:

```text
myfschool_backend/Grade/src/main/resources/schema.sql
myfschool_backend/Grade/src/main/resources/data_final.sql
```

File `schema.sql` tao cac bang:

- `Roles` & `Users` & `User_Roles`: Phan quyen va tai khoan nguoi dung (Student, Admin, Teacher).
- `Teachers` & `Students`: Ho so chi tiet giao vien va hoc sinh.
- `SchoolYears`, `SchoolClasses`, `Subjects`: Nam hoc, lop hoc, mon hoc.
- `TimeSlots`, `ClassSchedules`, `TeacherAssignments`: Tiet hoc, thoi khoa bieu, phan cong giang day.
- `Grades`: Bang diem voi cac cot tinh toan tu dong (AverageScore, LetterGrade, GPA4).
- `LeaveRequests` & `LeaveRequestStatusHistory`: Don xin phep va lich su duyet don.
- `RewardDisciplineTypes` & `RewardDisciplines`: Khen thuong va ky luat.
- `Events` & `News`: Su kien va tin tuc truong hoc.
- `Files`: Quan ly tap tin dinh kem.


## Backend

Backend chay tai:

```text
http://localhost:8080
```

*(Luu y: Tren Android Emulator, backend duoc goi qua `http://10.0.2.2:8080`)*

Cau hinh ket noi SQL Server nam trong:

```text
myfschool_backend/Grade/src/main/resources/application.properties
```

Mac dinh dang dung:

```properties
spring.datasource.url=jdbc:sqlserver://localhost:1433;databaseName=GradeDB;encrypt=false;trustServerCertificate=true;characterEncoding=UTF-8
spring.datasource.username=sa
spring.datasource.password=123
spring.datasource.driver-class-name=com.microsoft.sqlserver.jdbc.SQLServerDriver
server.port=8080
```

Neu may co cau hinh SQL Server khac (username, password hoac port), hay cap nhat file `application.properties` tuong ung.

### Chay backend bang IntelliJ IDEA / Eclipse

1. Mo thu muc `myfschool_backend/Grade` duoi dang Maven Project.
2. Cho Maven tai het cac dependencies.
3. Chay class khoi dong:

```text
com.jetbrains.grade.GradeApplication
```

### Chay backend bang terminal / PowerShell

Neu may da cai Maven:

```powershell
cd myfschool_backend\Grade
mvn spring-boot:run
```

Kiem tra backend hoat dong:

```powershell
# Kiem tra danh sach mon hoc / lop
Invoke-RestMethod -Uri "http://localhost:8080/api/classes" -Method Get
```


## API Endpoints

### 1. Authentication (`/api/auth`)
```text
POST /api/auth/login                  # Dang nhap bang so dien thoai & mat khau (BCrypt)
```

### 2. Grade Management (`/api/grades`)
```text
GET    /api/grades                     # Lay tat ca diem
GET    /api/grades/{id}                # Lay chi tiet diem theo ID
GET    /api/grades/user/{userId}       # Lay danh sach diem cua hoc sinh theo UserID
GET    /api/grades/class/{classId}     # Lay danh sach diem theo Lop
POST   /api/grades                     # Tao ban ghi diem moi (co kiem tra trung lap)
PUT    /api/grades/{id}                # Cap nhat diem (chuyen can, giua ky, cuoi ky)
DELETE /api/grades/{id}                # Xoa ban ghi diem
```

### 3. Leave Requests (`/api/leave-requests`)
```text
POST   /api/leave-requests             # Tao don xin phep nghi hoc moi
GET    /api/leave-requests             # Lay tat ca don xin phep (danh cho Admin)
GET    /api/leave-requests/user/{userId} # Lay danh sach don cua hoc sinh theo UserID
PATCH  /api/leave-requests/{id}/status # Admin duyet / tu choi don kem ghi chu
```

### 4. Schedule / Thoi khoa bieu (`/api/schedules`)
```text
GET    /api/schedules/user/{userId}    # Lay thoi khoa bieu theo UserID hoc sinh
GET    /api/schedules/class/{classId}  # Lay thoi khoa bieu theo ClassID
```

### 5. Events (`/api/events`)
```text
GET    /api/events                     # Lay danh sach su kien truong hoc
```

### 6. News (`/api/news`)
```text
GET    /api/news                       # Lay danh sach tin tuc
GET    /api/news/{id}                  # Xem chi tiet tin tuc
```

### 7. Contacts (`/api/contacts`)
```text
GET    /api/contacts/user/{userId}     # Lay danh ba giao vien bo mon cua hoc sinh
```

### 8. Rewards & Discipline (`/api/rewards-discipline`)
```text
GET    /api/rewards-discipline         # Lay tat ca khen thuong / ky luat
GET    /api/rewards-discipline/user/{userId} # Lay theo UserID hoc sinh
GET    /api/rewards-discipline/class/{classId} # Lay theo ClassID
```

### 9. School Classes (`/api/classes`)
```text
GET    /api/classes                    # Lay danh sach tat ca lop hoc
```


## Mobile App (Flutter)

Ung dung di dong duoc phat trien bang Flutter, ho tro Android, iOS va Desktop.

### Yeu cau moi truong
- Flutter SDK (phien ban 3.x tro len).
- Android Studio / VS Code voi Flutter extension.
- May ao Android Emulator hoac thiet bi that bat USB Debugging.

### Cai dat va khoi chay

```powershell
cd myfschool_mobile
flutter pub get
flutter run
```

### Cau hinh API URL
Trong cac service tai `myfschool_mobile/lib/services/`:
- Mac dinh: `http://10.0.2.2:8080/api` (dia chi gateway tro den localhost cua may chu tu Android Emulator).
- Neu chay tren thiet bi that qua Wi-Fi: doi `10.0.2.2` thanh dia chi IPv4 may tinh (vi du `http://192.168.1.x:8080/api`).
- Neu chay tren Windows Desktop: dung `http://localhost:8080/api`.


## Kiem thu tu dong (Automated Tests)

He thong kiem thu duoc to chuc chuyen nghiep theo 2 tang rieng biet:

### 1. Flutter Unit & Widget Tests
Kiem thu toan bo Models (serialization, fallback defaults), Services (UserSession, singleton) va UI smoke test:

```powershell
cd myfschool_mobile
flutter test
```

*Ket qua: **46/46 tests passed (100%)**.*

### 2. API Integration Tests (Node.js)
Bo test tu dong 30 test cases truc tiep voi REST API backend (Auth, Grade CRUD, Leave Request state transition, Events, News, Schedule, Classes):

```powershell
cd Test
.\run-tests.ps1
```

Hoac:

```powershell
cd Test
node automated/api-tests.mjs
```

### 3. Tai lieu dac ta kiem thu
- [Test/01_Project_Analysis.md](Test/01_Project_Analysis.md): Phan tich toan dien kien truc, actors va vung rui ro cao.
- [Test/02_Test_Analysis.md](Test/02_Test_Analysis.md): Ky thuat ISTQB (Equivalence Partitioning, Boundary Value, Decision Table, State Transition).
- [Test/03_Test_Cases.md](Test/03_Test_Cases.md): Bang dac ta 50 test cases chi tiet.
- [Test/README_Automated_Tests.md](Test/README_Automated_Tests.md): Huong dan chay bo test tu dong.


## Chuc nang da ket noi giua Mobile va Backend

- **Xac thuc**: Dang nhap bang so dien thoai va mat khau ma hoa BCrypt qua `/api/auth/login`.
- **Quan ly diem**: Xem bang diem ca nhan, diem trung binh, GPA4, diem chu; them / sua / xoa diem tu controller.
- **Xin phep nghi hoc**: Tao don moi kem validate ngay thang, xem danh sach don ca nhan, Admin duyet / tu choi kem ly do.
- **Thoi khoa bieu**: Hien thi lich hoc theo cac thu trong tuan, tiet hoc, phong hoc, giao vien giang day.
- **Tin tuc & Su kien**: Xem danh sach tin tuc, chi tiet tin tuc, lich su kien sap dien ra.
- **Lien he**: Danh ba giao vien giang day truc tiep cua lop, lien he phong ban nha truong.
- **Khen thuong & Ky luat**: Xem quyet dinh khen thuong, ky luat cua hoc sinh.
