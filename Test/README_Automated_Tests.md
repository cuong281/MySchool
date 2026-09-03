# MySchool Automated Test Runner

Thu muc nay chua code de chay cac test case trong `03_Test_Cases.md`.

## Tong quan

MySchool su dung 2 tang test:

1. **API Integration Tests** (Node.js): Test truc tiep REST API cua backend.
2. **Flutter Unit Tests**: Test models va services cua ung dung mobile.

## Dieu kien truoc khi chay

### API Tests
- Node.js 18+.
- Backend dang chay tai `http://localhost:8080`.
- Database `GradeDB` da duoc seed (schema.sql + data_final.sql).

### Flutter Unit Tests
- Flutter SDK da cai dat.
- Da chay `flutter pub get` trong thu muc `myfschool_mobile`.

## Lenh chay

### API Tests

Chay tat ca API tests:

```powershell
cd MySchool\Test
.\run-tests.ps1
```

Hoac:

```powershell
cd MySchool\Test
node automated/api-tests.mjs
```

Co the override URL:

```powershell
$env:API_BASE_URL="http://localhost:8080/api"
node automated/api-tests.mjs
```

### Flutter Unit Tests

Chay tat ca Flutter tests:

```powershell
cd MySchool\myfschool_mobile
flutter test
```

Chay mot file test cu the:

```powershell
flutter test test/models/grade_test.dart
```

Chay voi coverage:

```powershell
flutter test --coverage
```

## Mapping chinh

### API Tests (`Test/automated/`)
- `test-harness.mjs`: Custom test framework (test/step/skip/summary/apiGet/apiPost/apiPut/apiPatch/apiDelete).
- `api-tests.mjs`: 30 API test cases bao phu Auth, Grade CRUD, Leave Request, Events, News, Schedule, Classes.
- `run-all.mjs`: Orchestrator chay tat ca test suites.

### Flutter Unit Tests (`myfschool_mobile/test/`)
- `models/user_model_test.dart`: UserModel fromMap/toMap, role getter, alternative IDs.
- `models/grade_test.dart`: Grade fromJson/toJson, copyWith, numeric types.
- `models/event_model_test.dart`: EventModel fromJson/toJson roundtrip.
- `models/news_model_test.dart`: NewsModel publishedDate parsing.
- `models/schedule_model_test.dart`: SchedulePeriodModel, ScheduleDayModel fromMap.
- `models/contact_model_test.dart`: Contact fromJson/toJson.
- `models/school_class_model_test.dart`: SchoolClassModel fromJson, default status.
- `models/reward_discipline_model_test.dart`: RewardDisciplineModel nested user.
- `models/request_model_test.dart`: LeaveRequest model, RequestStore LIFO.
- `services/user_session_test.dart`: UserSession singleton, setUser, fullName, clear.

## Test framework

| Tang | Framework | Dependencies |
|---|---|---|
| API Tests | Custom Node.js harness (ES Modules) | Khong can npm install — dung node:assert va fetch native |
| Flutter Tests | flutter_test (SDK) | Da co trong pubspec.yaml |

## Luu y

- API tests tao du lieu test moi voi ma unique. Nen reset DB seed neu muon moi lan chay co dataset sach.
- Mot so negative test co the nhan HTTP 500 thay vi 400/401 neu backend chua co global exception handler cho tat ca truong hop.
- Flutter unit tests khong can backend — chay offline hoan toan.
- Test ID mapping: TC-API-xxx cho API tests, TC-UNIT-xxx cho Flutter unit tests.
