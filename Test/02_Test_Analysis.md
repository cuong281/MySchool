# Phan tich test theo ISTQB - MySchool

## 1. Test basis

Tai lieu va artifact lam co so thiet ke test:

- API endpoints tu cac Controller classes.
- Business rules trong cac Service classes.
- Data constraints tu schema.sql.
- Model serialization trong Flutter models.
- Auth flow tu AuthService va AuthController.

## 2. Chuc nang can test

| ID | Chuc nang | Can test | Muc uu tien |
|---|---|---|---|
| F01 | Auth login | Phone + password validation, BCrypt, isActive check | Critical |
| F02 | Grade CRUD | Lay/them/sua/xoa diem, duplicate check, computed columns | Critical |
| F03 | Leave Request | Tao don, date validation, status transition | Critical |
| F04 | Xem diem theo user/class | Query by userId, classId | High |
| F05 | Xem don theo user | Query don xin phep by userId | High |
| F06 | Duyet/tu choi don | Admin cap nhat status, ghi history | High |
| F07 | Xem events | Lay danh sach su kien | Medium |
| F08 | Xem news | Lay danh sach va chi tiet tin tuc | Medium |
| F09 | Xem schedule | Thoi khoa bieu theo user/class | Medium |
| F10 | Xem classes | Danh sach lop | Medium |
| F11 | Model serialization | fromJson/toJson cua tat ca Flutter models | High |
| F12 | UserSession | Singleton session management | High |

## 3. Ky thuat test ISTQB de xuat

### 3.1 Equivalence Partitioning

| Doi tuong | Partition hop le | Partition khong hop le |
|---|---|---|
| Phone number | So dien thoai ton tai + active | Rong, null, so khong ton tai |
| Password | Mat khau dung (BCrypt match) | Sai, rong, null |
| Grade scores | 0.0 - 10.0 | So am (neu validate) |
| Leave request dates | fromDate >= today, toDate >= fromDate | fromDate < today, toDate < fromDate |
| Leave request reason | Chuoi co ky tu | Rong, null, chi space |
| Grade duplicate | Combination chua ton tai | Combination da ton tai |

### 3.2 Boundary Value Analysis

| Truong/rule | Gia tri bien can test |
|---|---|
| fromDate | today - 1, today, today + 1 |
| toDate so voi fromDate | fromDate - 1, fromDate, fromDate + 1 |
| attendanceScore | 0.0, 10.0 |
| Reason string | Rong, 1 ky tu |

### 3.3 Decision Table cho tao don xin phep

| Rule | userId valid | fromDate >= today | toDate >= fromDate | reason not blank | Ket qua |
|---|---|---|---|---|---|
| R1 | Yes | Yes | Yes | Yes | Tao don thanh cong (201) |
| R2 | Yes | No | Yes | Yes | Tu choi: fromDate invalid |
| R3 | Yes | Yes | No | Yes | Tu choi: toDate invalid |
| R4 | Yes | Yes | Yes | No | Tu choi: reason blank |
| R5 | No | Yes | Yes | Yes | Tu choi: student not found |

### 3.4 State Transition cho don xin phep

| Trang thai hien tai | Action | Trang thai moi | Hop le? |
|---|---|---|---|
| Cho duyet | Admin duyet | Da duyet | Hop le |
| Cho duyet | Admin tu choi | Tu choi | Hop le |
| Da duyet | Admin duyet lai | Da duyet | Can xem xet |
| Tu choi | Admin duyet | Da duyet | Can xem xet |

## 4. Test data de xuat

| Nhom data | Gia tri mau |
|---|---|
| User hop le | Phone va password tu seed data |
| User sai | Phone khong ton tai, password sai |
| Grade hop le | studentId/subjectId/schoolYearId tu seed |
| Leave request hop le | fromDate = tomorrow, toDate = tomorrow + 1, reason = "Test" |
| Leave request invalid | fromDate = yesterday, toDate < fromDate, reason blank |

## 5. Entry/Exit criteria

### Entry criteria

- SQL Server co database `GradeDB` va seed script da chay thanh cong.
- Backend chay tai `http://localhost:8080`.
- Flutter SDK da cai dat.
- Test data biet truoc hoac moi test co setup rieng.

### Exit criteria

- Tat ca test case Priority Critical va High pass.
- Khong con defect nghiem trong ve auth, grade CRUD, leave request flow.
- Cac loi Medium duoc ghi nhan.
- Flutter unit tests pass 100%.
