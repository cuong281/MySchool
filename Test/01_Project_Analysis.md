# Phan tich du an - MySchool

## 1. Pham vi thong tin da phan tich

Nguon thong tin duoc doc va doi chieu:

- `myfschool_mobile/pubspec.yaml` va source code Flutter
- `myfschool_backend/Grade/pom.xml` va source code Spring Boot
- Backend controllers trong `com.jetbrains.grade.controller`
- Backend services trong `com.jetbrains.grade.service`
- Database schema trong `src/main/resources/schema.sql`
- Backend config trong `application.properties`

## 2. Muc tieu he thong

MySchool la ung dung quan ly truong hoc gom backend REST API va ung dung mobile Flutter. Muc tieu chinh:

- Dang nhap bang so dien thoai va mat khau (BCrypt).
- Quan ly diem hoc sinh (xem, them, sua, xoa).
- Quan ly don xin phep (tao, duyet, tu choi).
- Xem thoi khoa bieu hoc sinh theo user hoac lop.
- Xem su kien truong hoc.
- Xem tin tuc truong hoc.
- Xem thong tin lien he giao vien.
- Xem lich su khen thuong/ky luat.
- Quan ly danh sach lop hoc.

## 3. Kien truc tong quan

| Thanh phan | Cong nghe | Vai tro |
|---|---|---|
| Mobile | Flutter (Dart), http, sqflite | Ung dung di dong goi API backend |
| Backend | Java 17, Spring Boot 3.1.5, Spring Data JPA, Spring Security | REST API tai `/api`, xu ly nghiep vu |
| Database | SQL Server (GradeDB) | Luu Users, Students, Grades, Schedules, Events, News, LeaveRequests |
| Auth | BCrypt, phone+password login | Khong dung JWT, tra ve user info truc tiep |

## 4. Cac module/chuc nang chinh

| Module | Chuc nang hien co | Ghi chu |
|---|---|---|
| Auth | Dang nhap bang phone + password | BCrypt hash, kiem tra isActive |
| Grade | CRUD diem hoc sinh, xem theo user/class | Computed columns (averageScore, letterGrade, gpa4) |
| Leave Request | Tao don, xem theo user, admin duyet/tu choi | Status flow: Cho duyet → Da duyet / Tu choi |
| Schedule | Xem thoi khoa bieu theo user hoac class | Read-only |
| Event | Xem danh sach su kien | Read-only |
| News | Xem danh sach tin tuc, chi tiet | Read-only |
| Contact | Xem thong tin giao vien theo user | Read-only |
| Reward/Discipline | Xem khen thuong/ky luat theo user/class | Read-only |
| School Class | Xem danh sach lop | Read-only |

## 5. API endpoints

| Method | Endpoint | Muc dich |
|---|---|---|
| POST | `/api/auth/login` | Dang nhap |
| GET | `/api/grades` | Lay tat ca diem |
| GET | `/api/grades/{id}` | Lay diem theo ID |
| GET | `/api/grades/user/{userId}` | Lay diem theo user |
| GET | `/api/grades/class/{classId}` | Lay diem theo lop |
| POST | `/api/grades` | Them diem moi |
| PUT | `/api/grades/{id}` | Cap nhat diem |
| DELETE | `/api/grades/{id}` | Xoa diem |
| POST | `/api/leave-requests` | Tao don xin phep |
| GET | `/api/leave-requests` | Lay tat ca don |
| GET | `/api/leave-requests/user/{userId}` | Lay don theo user |
| PATCH | `/api/leave-requests/{id}/status` | Cap nhat trang thai don |
| GET | `/api/events` | Lay su kien |
| GET | `/api/news` | Lay tin tuc |
| GET | `/api/news/{id}` | Lay chi tiet tin |
| GET | `/api/schedules/user/{userId}` | Lay thoi khoa bieu |
| GET | `/api/schedules/class/{classId}` | Lay TKB theo lop |
| GET | `/api/contacts/user/{userId}` | Lay lien he giao vien |
| GET | `/api/rewards-discipline` | Lay tat ca khen thuong/ky luat |
| GET | `/api/rewards-discipline/user/{userId}` | Lay theo user |
| GET | `/api/rewards-discipline/class/{classId}` | Lay theo lop |
| GET | `/api/classes` | Lay danh sach lop |

## 6. Actors

| Actor | Mo ta | Quyen/chuc nang |
|---|---|---|
| Student | Hoc sinh dang nhap | Xem diem, xem TKB, tao don xin phep, xem tin tuc/su kien |
| Admin/Teacher | Quan tri vien hoac giao vien | Quan ly diem, duyet don, xem tat ca du lieu |

## 7. Cac diem rui ro cao

| Risk area | Muc do | Ly do |
|---|---|---|
| Authentication | Cao | Sai phone/password, user inactive, BCrypt matching |
| Grade CRUD | Cao | Duplicate check (student+subject+year+semester), computed columns |
| Leave Request status flow | Cao | Validate dates, status transition, admin approval |
| Date validation | Trung binh-Cao | fromDate >= today, toDate >= fromDate |
| API error handling | Trung binh | Mot so exception co the tra 500 thay vi 400 |
