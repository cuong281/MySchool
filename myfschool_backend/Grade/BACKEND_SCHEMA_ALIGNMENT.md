# Backend Schema Alignment

Tai lieu nay mo ta cac thay doi can thuc hien trong backend Spring Boot de khop voi schema moi:

- bo `UserRoles`
- them lien ket `Users -> Students`
- doi cac module nghiep vu hoc sinh sang dung `StudentID` that
- chuan hoa lai bang `Grades`, `LeaveRequests`, `Events`, `RewardDisciplines`

## 1. Entity can sua

### `Role.java`
- Giu lai bang `Roles`
- Nen co:
  - `id -> RoleID`
  - `roleName -> RoleName`
  - `isActive`
- Khong can map many-to-many sang `UserRoles`

### `User.java`
- Giu `@ManyToOne @JoinColumn(name = "RoleID")`
- Them cac cot:
  - `lastLoginAt`
  - `createdAt`
  - `updatedAt`
- Co the them:
  - `@OneToOne(mappedBy = "user") private Student student;`

### `Student.java`
- Can doi thanh entity trung tam cua nghiep vu hoc sinh
- Nen co cac field:
  - `id -> StudentID`
  - `@OneToOne @JoinColumn(name = "UserID", unique = true) private User user`
  - `@ManyToOne @JoinColumn(name = "ClassID") private SchoolClass schoolClass`
  - `studentCode`
  - `fullName`
  - `dateOfBirth`
  - `gender`
  - `address`
  - `parentName`
  - `parentPhone`
  - `status`
  - `createdAt`
  - `updatedAt`

### `SchoolYear.java`
- Dam bao map:
  - `SchoolYearID`
  - `YearName`
  - `StartDate`
  - `EndDate`
  - `IsActive`

### `SchoolClass.java`
- Dam bao map:
  - `ClassID`
  - `ClassName`
  - `SchoolYearID`
  - `HomeroomTeacherID`
  - `Status`

### `Teacher.java`
- Doi `phone` thanh `phoneNumber` neu hien tai field dang lech ten cot
- Dam bao map:
  - `TeacherID`
  - `FullName`
  - `Email`
  - `PhoneNumber`
  - `AvatarUrl`
  - `Status`

### `Subject.java`
- Dam bao map:
  - `SubjectID`
  - `SubjectCode`
  - `SubjectName`
  - `IsActive`
- Neu hien tai entity dang dung `getName()`, can doi ro rang sang `getSubjectName()` hoac map alias dung

### `TeacherAssignment.java`
- Giu lai
- Dam bao cac field:
  - `TeacherID`
  - `SubjectID`
  - `ClassID`
  - `RoleType`
  - `CreatedAt`

### `TimeSlot.java`
- Giu lai
- Dung `LocalTime` cho `StartTime`, `EndTime`

### `ClassSchedule.java`
- Giu lai
- Dam bao map:
  - `ClassID`
  - `DayOfWeek`
  - `TimeSlotID`
  - `SubjectID`
  - `TeacherID`
  - `RoomName`
  - `Status`

### `Grade.java`
- Can sua lon
- Khong dung kieu cu:
  - `studentId` string
  - `studentName`
  - `className`
  - `subjectCode`
  - `subjectName`
  - `academicYear` string
- Doi sang:
  - `id -> GradeID`
  - `@ManyToOne @JoinColumn(name = "StudentID") private Student student`
  - `@ManyToOne @JoinColumn(name = "SubjectID") private Subject subject`
  - `@ManyToOne @JoinColumn(name = "SchoolYearID") private SchoolYear schoolYear`
  - `semester`
  - `attendanceScore`
  - `midtermScore`
  - `finalScore`
  - `averageScore` read-only
  - `letterGrade` read-only
  - `gpa4` read-only
  - `createdAt`
  - `updatedAt`

### `LeaveRequest.java`
- Can sua lon
- Hien tai dang dung `userId`
- Doi sang:
  - `id -> RequestID`
  - `@ManyToOne @JoinColumn(name = "StudentID") private Student student`
  - `requestType`
  - `fromDate`
  - `toDate`
  - `reason`
  - `status`
  - `@ManyToOne @JoinColumn(name = "AttachmentFileID") private FileEntity attachmentFile`
  - `@ManyToOne @JoinColumn(name = "ProcessedByUserID") private User processedBy`
  - `processedAt`
  - `adminNote`
  - `createdAt`
  - `updatedAt`

### `Event.java`
- Doi:
  - `date` string -> `startAt` (`LocalDateTime`)
  - `time` string -> bo, hoac dung `endAt`
- Nen co:
  - `title`
  - `description`
  - `startAt`
  - `endAt`
  - `location`
  - `category`
  - `status`
  - `@ManyToOne @JoinColumn(name = "BannerFileID") private FileEntity bannerFile`
  - `@ManyToOne @JoinColumn(name = "CreatedByUserID") private User createdBy`
  - `createdAt`
  - `updatedAt`

### `RewardDiscipline.java`
- Hien tai dang dung `User`
- Doi sang:
  - `id -> RecordID`
  - `@ManyToOne @JoinColumn(name = "StudentID") private Student student`
  - `@ManyToOne @JoinColumn(name = "TypeID") private RewardDisciplineType type`
  - `@ManyToOne @JoinColumn(name = "SchoolYearID") private SchoolYear schoolYear`
  - `semester`
  - `decisionNumber`
  - `content`
  - `@ManyToOne @JoinColumn(name = "IssuedByUserID") private User issuedBy`
  - `issuedDate`
  - `@ManyToOne @JoinColumn(name = "FileID") private FileEntity file`
  - `createdAt`

### Them moi `RewardDisciplineType.java`
- Field:
  - `id -> TypeID`
  - `typeCode`
  - `typeName`
  - `groupName`
  - `isActive`

### Them moi `Announcement.java`
- Field:
  - `AnnouncementID`
  - `title`
  - `content`
  - `audienceType`
  - `status`
  - `publishedAt`
  - `createdBy`
  - `createdAt`
  - `updatedAt`

### Them moi `NotificationLog.java`
- Field:
  - `NotificationID`
  - `user`
  - `sourceType`
  - `sourceID`
  - `title`
  - `message`
  - `isRead`
  - `createdAt`
  - `readAt`

### Them moi `LeaveRequestStatusHistory.java`
- Field:
  - `HistoryID`
  - `leaveRequest`
  - `changedBy`
  - `oldStatus`
  - `newStatus`
  - `note`
  - `changedAt`

### Them moi `FileEntity.java`
- Dat ten khac `File` de tranh trung voi `java.io.File`
- Field:
  - `FileID`
  - `uploadedBy`
  - `fileName`
  - `fileUrl`
  - `fileType`
  - `fileSize`
  - `createdAt`

## 2. Repository can sua

### `UserRepository.java`
- Giu:
  - `findByPhoneNumberAndIsActiveTrue`
  - `findByUsername`
- Co the them:
  - `Optional<User> findByIdAndIsActiveTrue(Integer id)`

### `StudentRepository.java`
- Can them:
  - `Optional<Student> findByUserId(Integer userId)`
  - `Optional<Student> findByStudentCode(String studentCode)`

### `GradeRepository.java`
- Can viet lai theo schema moi
- Bo cac method cu:
  - `findByStudentId(String studentId)`
  - `findByClassName(String className)`
  - `existsByStudentIdAndSubjectCodeAndAcademicYearAndSemester(...)`
- Doi thanh:
  - `List<Grade> findByStudentId(Integer studentId)`
  - `List<Grade> findByStudentSchoolClassId(Integer classId)`
  - `List<Grade> findByStudentIdAndSemester(Integer studentId, Integer semester)`
  - `boolean existsByStudentIdAndSubjectIdAndSchoolYearIdAndSemester(...)`

### `LeaveRequestRepository.java`
- Bo query theo `userId`
- Doi thanh:
  - `List<LeaveRequest> findByStudentIdOrderByCreatedAtDesc(Integer studentId)`
  - `List<LeaveRequest> findByStatusOrderByCreatedAtDesc(String status)`

### `RewardDisciplineRepository.java`
- Bo query theo `userId`
- Doi thanh:
  - `List<RewardDiscipline> findByStudentIdOrderByIssuedDateDesc(Integer studentId)`

### `EventRepository.java`
- Giu, co the them:
  - `List<Event> findByStatusOrderByStartAtAsc(String status)`

### Them moi:
- `AnnouncementRepository`
- `NotificationLogRepository`
- `RewardDisciplineTypeRepository`
- `FileRepository`
- `LeaveRequestStatusHistoryRepository`

## 3. Service can sua

### `AuthController` / `AuthService`
- Sau khi login thanh cong:
  - cap nhat `LastLoginAt`
  - tim `Student` theo `UserID` neu role = Student
- `AuthResponse` nen bo sung:
  - `studentId`
  - `studentCode`
  - `classId`
  - `className`
- Day la diem then chot de Flutter khong phai doan `studentId`

### `ScheduleService.java`
- Hien tai sai vi dang nhan `studentId` truc tiep tu Flutter trong khi Flutter dang gui `user.id`
- Sau refactor:
  - neu controller nhan `studentId`, thi Flutter phai gui dung `StudentID`
  - hoac them endpoint moi:
    - `/api/schedules/user/{userId}`
  - trong service:
    - `Student student = studentRepository.findByUserId(userId)...`
- Day la huong de an toan hon cho app hien tai

### `ContactService.java`
- Tuong tu `ScheduleService`
- Nen doi endpoint sang:
  - `/api/contacts/user/{userId}`
  - roi service tim `Student` qua `userId`

### `GradeService.java`
- Doi toan bo logic tu string sang FK that
- Student xem diem:
  - tim theo `studentId` int
- Admin xem theo lop:
  - tim theo `classId`
- Khi tao sua diem:
  - validate `StudentID`, `SubjectID`, `SchoolYearID` ton tai

### `LeaveRequestService.java`
- Doi tu `userId` sang `studentId`
- Khi admin update status:
  - validate status trong tap hop hop le
  - cap nhat `processedBy`
  - cap nhat `processedAt`
  - luu `adminNote`
  - ghi them 1 dong vao `LeaveRequestStatusHistory`

### `RewardDisciplineService.java`
- Doi query theo `studentId`
- Khi tao record:
  - validate `TypeID`, `SchoolYearID`, `IssuedByUserID`

### `EventService.java`
- Doi logic ngay gio sang `LocalDateTime`
- Co the them:
  - lay event sap toi
  - lay event dang published

### Them moi:
- `AnnouncementService`
- `NotificationService`
- `FileService`

## 4. Controller can sua

### `AuthController.java`
- Response login can tra them:
  - `studentId`
  - `studentCode`
  - `classId`
  - `className`

### `ScheduleController.java`
- Nen doi endpoint tu:
  - `/api/schedules/student/{studentId}`
- Thanh 1 trong 2 cach:
  - giu nguyen, nhung Flutter phai co `studentId` that
  - hoac doi thanh `/api/schedules/user/{userId}`

### `ContactController.java`
- Tuong tu `ScheduleController`

### `LeaveRequestController.java`
- POST create:
  - nhan `studentId`, khong nhan `userId`
- PATCH status:
  - nhan them `processedByUserId`, `adminNote`
- GET all:
  - nen co filter status

### `RewardDisciplineController.java`
- Doi endpoint:
  - `/api/rewards-discipline/student/{studentId}`
- Khong dung `/user/{userId}` nua

### `GradeController.java`
- Doi endpoint student:
  - `/api/grades/student/{studentId}` voi `studentId` la int that
- Them endpoint admin:
  - `/api/grades/class/{classId}`

### Them moi:
- `AnnouncementController`
- `NotificationController`

## 5. DTO can them hoac sua

### Sua `AuthResponse`
- Them:
  - `Integer studentId`
  - `String studentCode`
  - `Integer classId`
  - `String className`

### Them `LeaveRequestCreateRequest`
- `studentId`
- `requestType`
- `fromDate`
- `toDate`
- `reason`

### Them `LeaveRequestStatusUpdateRequest`
- `status`
- `processedByUserId`
- `adminNote`

### Them `GradeCreateUpdateRequest`
- `studentId`
- `subjectId`
- `schoolYearId`
- `semester`
- `attendanceScore`
- `midtermScore`
- `finalScore`

## 6. Config va migration

### `application.properties`
- Khi da chot schema:
  - khuyen nghi khong dung `spring.jpa.hibernate.ddl-auto=update`
  - doi sang `validate`
- Khuyen nghi bat 1 co che migration ro rang:
  - Flyway hoac Liquibase
- Neu chua dung migration tool:
  - it nhat chi giu 1 bo `schema_final.sql` va `data_final.sql`
  - bo cac file seed cu gay xung dot

## 7. Thu tu refactor de an toan

1. Tao schema moi va seed moi
2. Sua `Student.java` + `User.java` + `StudentRepository`
3. Sua `AuthResponse` + `AuthController`
4. Sua `ScheduleService` + `ContactService`
5. Sua `Grade.java` + `GradeRepository` + `GradeService`
6. Sua `LeaveRequest.java` + repository/service/controller
7. Sua `RewardDiscipline.java` + type entity/repository/service
8. Sua `Event.java`
9. Them `Announcement` va `Notification`

## 8. Diem quan trong nhat

Neu chi sua mot viec de app chay dung hon ngay lap tuc, hay sua:

- `Students` phai co `UserID`
- login phai tra ve `studentId`
- Flutter `Schedule`, `Contact`, `LeaveRequest`, `RewardDiscipline` phai dung `studentId` that

Do la nut that lon nhat cua project hien tai.
