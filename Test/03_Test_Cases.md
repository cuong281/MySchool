# Test cases chi tiet - MySchool

## 1. API va backend

| Test Case ID | Title | Preconditions | Test Steps | Test Data | Expected Result | Priority | Test Type |
|---|---|---|---|---|---|---|---|
| TC-API-001 | Login thanh cong | Backend dang chay, user ton tai | 1. Goi `POST /api/auth/login` | phone + password hop le | HTTP 200; response co userId, username, roles | Critical | Functional |
| TC-API-002 | Login sai password | Backend dang chay | 1. Goi `POST /api/auth/login` | phone hop le, password sai | HTTP 401; bao loi sai thong tin | Critical | Negative |
| TC-API-003 | Login phone khong ton tai | Backend dang chay | 1. Goi `POST /api/auth/login` | phone=9999999999 | HTTP 401; bao loi | Critical | Negative |
| TC-API-004 | Login thieu phone | Backend dang chay | 1. Goi `POST /api/auth/login` | Chi co password | HTTP 400; bao loi thieu thong tin | High | Negative |
| TC-API-005 | Login thieu password | Backend dang chay | 1. Goi `POST /api/auth/login` | Chi co phone | HTTP 400; bao loi thieu thong tin | High | Negative |
| TC-API-006 | Login phone rong | Backend dang chay | 1. Goi `POST /api/auth/login` | phone rong | HTTP 400; bao loi | High | Negative |
| TC-API-007 | Lay tat ca grades | DB co grades | 1. Goi `GET /api/grades` | N/A | HTTP 200; mang grades | High | Functional |
| TC-API-008 | Lay grade theo ID | DB co grades | 1. Goi `GET /api/grades/{id}` | ID hop le | HTTP 200; grade object | High | Functional |
| TC-API-009 | Lay grade ID khong ton tai | Backend dang chay | 1. Goi `GET /api/grades/999999` | ID=999999 | HTTP 404; bao loi | High | Negative |
| TC-API-010 | Lay grades theo userId | Co user da login | 1. Goi `GET /api/grades/user/{userId}` | userId tu login | HTTP 200; mang grades | High | Functional |
| TC-API-011 | Lay grades theo classId | Co classId tu login | 1. Goi `GET /api/grades/class/{classId}` | classId | HTTP 200; mang grades | High | Functional |
| TC-API-012 | Tao grade moi | Co studentId, subjectId, schoolYearId | 1. Goi `POST /api/grades` | Grade data hop le | HTTP 201; grade object voi computed columns | Critical | Functional, Integration |
| TC-API-013 | Tao grade trung | Grade da ton tai cho combination | 1. Goi `POST /api/grades` voi duplicate | Trung student+subject+year+semester | HTTP 409; bao loi trung | Critical | Negative |
| TC-API-014 | Cap nhat grade | Co grade ton tai | 1. Goi `PUT /api/grades/{id}` | Scores moi | HTTP 200; grade updated | High | Functional |
| TC-API-015 | Cap nhat grade ID khong ton tai | Backend dang chay | 1. Goi `PUT /api/grades/999999` | ID=999999 | HTTP 404; bao loi | High | Negative |
| TC-API-016 | Xoa grade | Co grade tu test truoc | 1. Goi `DELETE /api/grades/{id}` | ID tu TC-API-012 | HTTP 200; success | High | Functional |
| TC-API-017 | Xoa grade ID khong ton tai | Backend dang chay | 1. Goi `DELETE /api/grades/999999` | ID=999999 | HTTP 404; bao loi | High | Negative |
| TC-API-018 | Tao don xin phep hop le | Co userId la student | 1. Goi `POST /api/leave-requests` | fromDate > today, toDate > fromDate | HTTP 201; requestId | Critical | Functional |
| TC-API-019 | Tao don thieu reason | Co userId | 1. Goi `POST /api/leave-requests` | reason rong | HTTP 400; bao loi | High | Negative |
| TC-API-020 | Tao don fromDate truoc hom nay | Co userId | 1. Goi `POST /api/leave-requests` | fromDate < today | HTTP 400; bao loi date | High | Negative, Boundary |
| TC-API-021 | Tao don toDate truoc fromDate | Co userId | 1. Goi `POST /api/leave-requests` | toDate < fromDate | HTTP 400; bao loi date | High | Negative, Boundary |
| TC-API-022 | Lay don theo userId | Co don da tao | 1. Goi `GET /api/leave-requests/user/{userId}` | userId | HTTP 200; mang don | High | Functional |
| TC-API-023 | Lay tat ca don (admin) | Co don trong DB | 1. Goi `GET /api/leave-requests` | N/A | HTTP 200; mang don | Medium | Functional |
| TC-API-024 | Cap nhat status don | Co don da tao | 1. Goi `PATCH /api/leave-requests/{id}/status` | status=Da duyet | HTTP 200; status updated | Critical | State Transition |
| TC-API-025 | Cap nhat status thieu field | Co don | 1. Goi `PATCH` thieu status | Thieu status | HTTP 400; bao loi | High | Negative |
| TC-API-026 | Lay danh sach events | DB co events | 1. Goi `GET /api/events` | N/A | HTTP 200; mang events | Medium | Functional |
| TC-API-027 | Lay danh sach news | DB co news | 1. Goi `GET /api/news` | N/A | HTTP 200; mang news | Medium | Functional |
| TC-API-028 | Lay news theo ID | DB co news | 1. Goi `GET /api/news/{id}` | ID hop le | HTTP 200; news object | Medium | Functional |
| TC-API-029 | Lay schedule theo userId | Co userId | 1. Goi `GET /api/schedules/user/{userId}` | userId | HTTP 200; mang schedule | Medium | Functional |
| TC-API-030 | Lay danh sach classes | DB co classes | 1. Goi `GET /api/classes` | N/A | HTTP 200; mang classes | Medium | Functional |

## 2. Flutter Unit Tests

| Test Case ID | Title | Preconditions | Test Steps | Expected Result | Priority | Test Type |
|---|---|---|---|---|---|---|
| TC-UNIT-001 | UserModel fromMap day du | N/A | Tao UserModel tu map day du | Tat ca fields map dung | High | Unit |
| TC-UNIT-002 | UserModel fromMap thieu | N/A | Tao UserModel tu map rong | Fallback defaults dung | High | Unit |
| TC-UNIT-003 | UserModel toMap roundtrip | N/A | fromMap → toMap → fromMap | Du lieu nhat quan | Medium | Unit |
| TC-UNIT-004 | Grade fromJson day du | N/A | Tao Grade tu JSON day du | Tat ca fields map dung | High | Unit |
| TC-UNIT-005 | Grade fromJson null | N/A | Tao Grade tu JSON rong | Fallback defaults dung | High | Unit |
| TC-UNIT-006 | Grade toJson id null | N/A | toJson khi id = null | JSON khong co key 'id' | High | Unit |
| TC-UNIT-007 | Grade copyWith | N/A | copyWith thay doi mot so fields | Chi fields chi dinh thay doi | Medium | Unit |
| TC-UNIT-008 | EventModel roundtrip | N/A | fromJson → toJson | Du lieu nhat quan | Medium | Unit |
| TC-UNIT-009 | NewsModel date parsing | N/A | fromJson voi publishedDate string | DateTime parse dung | High | Unit |
| TC-UNIT-010 | SchedulePeriodModel fromMap | N/A | Tao period tu map | Fields map dung | Medium | Unit |
| TC-UNIT-011 | ScheduleDayModel periods | N/A | Tao day voi periods list | Periods parse dung | Medium | Unit |
| TC-UNIT-012 | Contact roundtrip | N/A | fromJson → toJson | Du lieu nhat quan | Medium | Unit |
| TC-UNIT-013 | SchoolClassModel fromJson | N/A | Tao tu JSON | Fields map dung, status default | Medium | Unit |
| TC-UNIT-014 | RewardDisciplineModel nested | N/A | fromJson voi user object | userId, userName tu nested | High | Unit |
| TC-UNIT-015 | RequestStore add/clear | N/A | Add, kiem tra LIFO, clear | Hoat dong dung | Medium | Unit |
| TC-UNIT-016 | UserSession setUser | N/A | setUser va kiem tra fullName | fullName format "LastName FirstName" | High | Unit |
| TC-UNIT-017 | UserSession clear | N/A | setUser roi clear | currentUser = null | High | Unit |
| TC-UNIT-018 | UserSession fullName null | N/A | fullName khi chua login | Tra ve '' | Medium | Unit |
| TC-UNIT-019 | UserModel role getter | N/A | roles co va rong | Tra first hoac fallback 'Student' | Medium | Unit |
| TC-UNIT-020 | UserModel alternative IDs | N/A | fromMap voi userId, id, userID | Tat ca duoc chap nhan | Medium | Unit |
