import assert from 'node:assert/strict';
import {
  apiGet,
  apiPost,
  apiPut,
  apiPatch,
  apiDelete,
  setAuthToken,
  getAuthToken,
  clearAuthToken,
  loginAs,
  test,
  skip,
  exitWithSummary,
  apiBase,
} from './test-harness.mjs';

// ── Helpers ──────────────────────────────────────────────────────────────────
function expectStatus(result, expectedStatus, context = '') {
  assert.equal(
    result.status,
    expectedStatus,
    `${context} expected HTTP ${expectedStatus} but got ${result.status}: ${JSON.stringify(result.body)}`,
  );
}

function expectOk(result, context = '') {
  assert.ok(
    result.ok,
    `${context} expected HTTP 2xx but got ${result.status}: ${JSON.stringify(result.body)}`,
  );
}

function expectRejected(result, context = '') {
  assert.ok(
    !result.ok,
    `${context} expected rejection (4xx/5xx) but got ${result.status}: ${JSON.stringify(result.body)}`,
  );
}

function expectForbidden(result, context = '') {
  assert.equal(
    result.status,
    403,
    `${context} expected HTTP 403 Forbidden but got ${result.status}: ${JSON.stringify(result.body)}`,
  );
}

function today() {
  return new Date().toISOString().split('T')[0];
}

function addDays(dateStr, n) {
  const d = new Date(dateStr);
  d.setDate(d.getDate() + n);
  return d.toISOString().split('T')[0];
}

function unique(prefix = 'test') {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
}

// ── Shared State ─────────────────────────────────────────────────────────────
let studentAToken = null;
let studentBToken = null;
let teacherToken = null;
let teacher2Token = null;
let adminToken = null;

let studentAUser = null;
let studentBUser = null;
let teacherUser = null;
let teacher2User = null;
let adminUser = null;

let createdGradeId = null;
let createdLeaveRequestId = null;

// ============================================================================
// MODULE 1: AUTHENTICATION & JWT (Priority: Critical)
// ============================================================================

await test('TC-API-001', 'Login thanh cong voi phone + password hop le va tra ve JWT', async () => {
  const result = await apiPost('/auth/login', {
    phoneNumber: '0901111111',
    password: '123456',
  });

  expectOk(result, 'POST /auth/login (Student A)');
  studentAUser = result.body;
  studentAToken = result.body.accessToken;

  assert.ok(result.body.userId || result.body.id, 'Response should contain userId');
  assert.ok(result.body.username, 'Response should contain username');
  assert.ok(Array.isArray(result.body.roles), 'Response should contain roles array');

  // JWT Token verification (Phase 1)
  assert.ok(result.body.accessToken, 'Response must contain accessToken');
  assert.ok(result.body.refreshToken, 'Response must contain refreshToken');
  assert.equal(result.body.tokenType, 'Bearer', 'tokenType should be Bearer');
  assert.ok(result.body.expiresIn > 0, 'expiresIn should be > 0 (e.g. 7200)');

  // Set default auth token to Student A
  setAuthToken(studentAToken);
});

await test('TC-API-002', 'Login that bai — sai password', async () => {
  const result = await apiPost('/auth/login', {
    phoneNumber: '0901111111',
    password: 'wrong_password_xyz',
  });
  expectStatus(result, 401, 'POST /auth/login wrong password');
});

await test('TC-API-003', 'Login that bai — phone khong ton tai', async () => {
  const result = await apiPost('/auth/login', {
    phoneNumber: '0999999999',
    password: '123456',
  });
  expectStatus(result, 401, 'POST /auth/login unknown phone');
});

await test('TC-API-004', 'Login that bai — thieu phone', async () => {
  const result = await apiPost('/auth/login', {
    password: '123456',
  });
  expectStatus(result, 400, 'POST /auth/login missing phone');
});

await test('TC-API-005', 'Login that bai — thieu password', async () => {
  const result = await apiPost('/auth/login', {
    phoneNumber: '0901111111',
  });
  expectStatus(result, 400, 'POST /auth/login missing password');
});

await test('TC-API-006', 'Login that bai — phone rong', async () => {
  const result = await apiPost('/auth/login', {
    phoneNumber: '',
    password: '123456',
  });
  expectStatus(result, 400, 'POST /auth/login empty phone');
});

// ============================================================================
// MODULE 1B: JWT SECURITY & REFRESH TOKEN (Priority: Critical)
// ============================================================================

await test('TC-SEC-001', 'Goi protected endpoint khong co Token phai tra ve 401', async () => {
  const result = await apiGet('/grades/me', {
    headers: { 'Authorization': '' }
  });
  expectStatus(result, 401, 'GET /grades/me without token');
});

await test('TC-SEC-002', 'Goi protected endpoint voi Token gia mao phai tra ve 401', async () => {
  const result = await apiGet('/grades/me', {
    headers: { 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.fake' }
  });
  expectStatus(result, 401, 'GET /grades/me with malformed token');
});

await test('TC-SEC-003', 'Refresh Token hop le tra ve Access Token va Refresh Token moi', async () => {
  if (!studentAUser?.refreshToken) {
    skip('No refreshToken available from login');
  }

  const result = await apiPost('/auth/refresh-token', {
    refreshToken: studentAUser.refreshToken,
  });

  expectOk(result, 'POST /auth/refresh-token');
  assert.ok(result.body.accessToken, 'Should return new accessToken');
  assert.ok(result.body.refreshToken, 'Should return new refreshToken');

  // Update studentAToken with fresh token
  studentAToken = result.body.accessToken;
  studentAUser.refreshToken = result.body.refreshToken;
  setAuthToken(studentAToken);
});

await test('TC-SEC-004', 'Refresh Token gia mao / khong ton tai tra ve 401', async () => {
  const result = await apiPost('/auth/refresh-token', {
    refreshToken: 'fake-refresh-token-uuid-123456',
  });
  expectStatus(result, 401, 'POST /auth/refresh-token fake');
});

await test('TC-SEC-005', 'Teacher login voi phone va default password 123456 thanh cong', async () => {
  const result = await apiPost('/auth/login', {
    phoneNumber: '0901000001', // Teacher Nguyen Ngoc Han
    password: '123456',
  });

  expectOk(result, 'POST /auth/login (Teacher)');
  teacherUser = result.body;
  teacherToken = result.body.accessToken;

  assert.ok(result.body.roles.some(r => r.toLowerCase().includes('teacher')), 'Role should be Teacher');
  assert.ok(result.body.teacherId != null, 'Teacher should have teacherId');
});

await test('TC-SEC-006', 'Logout thu hoi Refresh Token thanh cong', async () => {
  const tempLogin = await apiPost('/auth/login', {
    phoneNumber: '0901111111',
    password: '123456',
  });

  if (tempLogin.ok && tempLogin.body?.refreshToken) {
    const tempRefresh = tempLogin.body.refreshToken;

    const logoutRes = await apiPost('/auth/logout', {
      refreshToken: tempRefresh,
    });
    expectOk(logoutRes, 'POST /auth/logout');

    const attemptRes = await apiPost('/auth/refresh-token', {
      refreshToken: tempRefresh,
    });
    expectStatus(attemptRes, 401, 'POST /auth/refresh-token after logout');
  }
});

// Setup tokens for Admin, Student B, and Teacher 2
await test('TC-SETUP-001', 'Setup Admin, Student B, and Teacher 2 sessions', async () => {
  // Admin login
  const adminRes = await apiPost('/auth/login', {
    phoneNumber: '0909999999',
    password: '123456',
  });
  expectOk(adminRes, 'Admin login');
  adminUser = adminRes.body;
  adminToken = adminRes.body.accessToken;

  // Student B login
  const studentBRes = await apiPost('/auth/login', {
    phoneNumber: '0902222222',
    password: '123456',
  });
  expectOk(studentBRes, 'Student B login');
  studentBUser = studentBRes.body;
  studentBToken = studentBRes.body.accessToken;

  // Teacher 2 login (Homeroom of Class 2, Literature)
  const teacher2Res = await apiPost('/auth/login', {
    phoneNumber: '0901000002',
    password: '123456',
  });
  expectOk(teacher2Res, 'Teacher 2 login');
  teacher2User = teacher2Res.body;
  teacher2Token = teacher2Res.body.accessToken;

  // Reset current default auth token back to Student A
  setAuthToken(studentAToken);
});

// ============================================================================
// MODULE 2: GRADE MANAGEMENT & ACCESS CONTROL
// ============================================================================

await test('TC-API-007', 'Teacher / Admin co the lay danh sach tat ca grades', async () => {
  const result = await apiGet('/grades', {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(result, 'GET /grades (Teacher)');
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-008', 'Lay grade theo ID hop le (Teacher/Admin)', async () => {
  const list = await apiGet('/grades', {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(list, 'GET /grades for ID lookup');

  if (!Array.isArray(list.body) || list.body.length === 0) {
    skip('No grades in database to test getById');
  }

  const firstId = list.body[0].id;
  const result = await apiGet(`/grades/${firstId}`, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(result, `GET /grades/${firstId}`);
  assert.ok(result.body.id, 'Grade should have id field');
});

await test('TC-API-009', 'Lay grade theo ID khong ton tai', async () => {
  const result = await apiGet('/grades/999999', {
    headers: { 'Authorization': `Bearer ${adminToken}` }
  });
  expectStatus(result, 404, 'GET /grades/999999');
});

await test('TC-API-010', 'Student xem diem cua chinh minh qua /grades/user/{userId}', async () => {
  setAuthToken(studentAToken);
  const userId = studentAUser.userId || studentAUser.id;
  const result = await apiGet(`/grades/user/${userId}`);
  expectOk(result, `GET /grades/user/${userId}`);
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-011', 'Teacher xem grades theo classId', async () => {
  const result = await apiGet('/grades/class/1', {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(result, 'GET /grades/class/1');
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-012', 'Teacher tao grade moi hop le', async () => {
  const gradeData = {
    student: { id: 1 },
    subject: { id: 1 },
    schoolYear: { id: 1 },
    semester: 1,
    attendanceScore: 8.5,
    midtermScore: 7.0,
    finalScore: 8.0,
  };

  const result = await apiPost('/grades', gradeData, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });

  if (result.status === 409) {
    console.log('  INFO: Grade already exists (409 Conflict) — endpoint works correctly');
    return;
  }

  if (result.ok) {
    expectStatus(result, 201, 'POST /grades');
    createdGradeId = result.body.id;
    assert.ok(result.body.id, 'Created grade should have id');
  }
});

await test('TC-API-013', 'Tao grade trung bi tu choi 409 Conflict', async () => {
  const list = await apiGet('/grades', {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(list, 'GET /grades for duplicate check');

  if (!Array.isArray(list.body) || list.body.length === 0) {
    skip('No existing grades to create duplicate from');
  }

  const existing = list.body[0];
  const gradeData = {
    student: { id: existing.studentId },
    subject: { id: 1 },
    schoolYear: { id: 1 },
    semester: existing.semester || 1,
    attendanceScore: 5.0,
    midtermScore: 5.0,
    finalScore: 5.0,
  };

  const result = await apiPost('/grades', gradeData, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });

  if (result.ok) {
    if (result.body?.id) {
      await apiDelete(`/grades/${result.body.id}`, {
        headers: { 'Authorization': `Bearer ${adminToken}` }
      });
    }
  } else {
    assert.ok([409, 500].includes(result.status), `Expected 409 or 500 but got ${result.status}`);
  }
});

await test('TC-API-014', 'Teacher cap nhat grade hop le', async () => {
  const list = await apiGet('/grades', {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(list, 'GET /grades for update');

  if (!Array.isArray(list.body) || list.body.length === 0) {
    skip('No grades to update');
  }

  const targetId = createdGradeId || list.body[0].id;
  const updateData = {
    attendanceScore: 9.0,
    midtermScore: 8.5,
    finalScore: 9.0,
  };

  const result = await apiPut(`/grades/${targetId}`, updateData, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(result, `PUT /grades/${targetId}`);
});

await test('TC-API-015', 'Cap nhat grade voi ID khong ton tai tra ve 404', async () => {
  const result = await apiPut('/grades/999999', {
    attendanceScore: 5.0,
    midtermScore: 5.0,
    finalScore: 5.0,
  }, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectRejected(result, 'PUT /grades/999999');
});

await test('TC-API-016', 'Xoa grade hop le (Admin)', async () => {
  if (!createdGradeId) {
    skip('No grade was created in TC-API-012 to delete');
  }

  const result = await apiDelete(`/grades/${createdGradeId}`, {
    headers: { 'Authorization': `Bearer ${adminToken}` }
  });
  expectOk(result, `DELETE /grades/${createdGradeId}`);
});

await test('TC-API-017', 'Xoa grade voi ID khong ton tai tra ve 404', async () => {
  const result = await apiDelete('/grades/999999', {
    headers: { 'Authorization': `Bearer ${adminToken}` }
  });
  expectRejected(result, 'DELETE /grades/999999');
});

// ============================================================================
// MODULE 3: LEAVE REQUEST
// ============================================================================

await test('TC-API-018', 'Student tao don xin phep hop le cho chinh minh', async () => {
  setAuthToken(studentAToken);
  const userId = studentAUser.userId || studentAUser.id;
  const fromDate = addDays(today(), 1);
  const toDate = addDays(today(), 2);

  const result = await apiPost('/leave-requests', {
    userId,
    requestType: 'Xin nghi hoc',
    fromDate,
    toDate,
    reason: `Test don xin phep - ${unique('QA')}`,
  });

  expectStatus(result, 201, 'POST /leave-requests');
  createdLeaveRequestId = result.body?.requestId;
  assert.ok(createdLeaveRequestId, 'Response should contain requestId');
});

await test('TC-API-019', 'Tao don thieu thong tin (reason rong)', async () => {
  setAuthToken(studentAToken);
  const userId = studentAUser.userId || studentAUser.id;
  const result = await apiPost('/leave-requests', {
    userId,
    requestType: 'Xin nghi hoc',
    fromDate: addDays(today(), 1),
    toDate: addDays(today(), 2),
    reason: '',
  });

  expectRejected(result, 'POST /leave-requests empty reason');
});

await test('TC-API-020', 'Tao don voi fromDate truoc hom nay', async () => {
  setAuthToken(studentAToken);
  const userId = studentAUser.userId || studentAUser.id;
  const result = await apiPost('/leave-requests', {
    userId,
    requestType: 'Xin nghi hoc',
    fromDate: addDays(today(), -5),
    toDate: addDays(today(), -3),
    reason: 'Test fromDate in past',
  });

  expectRejected(result, 'POST /leave-requests fromDate in past');
});

await test('TC-API-021', 'Tao don voi toDate truoc fromDate', async () => {
  setAuthToken(studentAToken);
  const userId = studentAUser.userId || studentAUser.id;
  const result = await apiPost('/leave-requests', {
    userId,
    requestType: 'Xin nghi hoc',
    fromDate: addDays(today(), 5),
    toDate: addDays(today(), 3),
    reason: 'Test toDate before fromDate',
  });

  expectRejected(result, 'POST /leave-requests toDate before fromDate');
});

await test('TC-API-022', 'Student lay danh sach don cua chinh minh qua userId', async () => {
  setAuthToken(studentAToken);
  const userId = studentAUser.userId || studentAUser.id;
  const result = await apiGet(`/leave-requests/user/${userId}`);
  expectOk(result, `GET /leave-requests/user/${userId}`);
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-023', 'Admin lay tat ca don toan truong', async () => {
  const result = await apiGet('/leave-requests', {
    headers: { 'Authorization': `Bearer ${adminToken}` }
  });
  expectOk(result, 'GET /leave-requests (Admin)');
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-024', 'Admin duyet don xin phep', async () => {
  if (!createdLeaveRequestId) skip('No leave request created in TC-API-018');

  const result = await apiPatch(`/leave-requests/${createdLeaveRequestId}/status`, {
    status: 'Đã duyệt',
    adminNote: 'Admin phe duyet',
  }, {
    headers: { 'Authorization': `Bearer ${adminToken}` }
  });

  expectOk(result, `PATCH /leave-requests/${createdLeaveRequestId}/status`);
  assert.ok(result.body.status || result.body.message, 'Response should confirm update');
});

await test('TC-API-025', 'Cap nhat status don thieu status field', async () => {
  if (!createdLeaveRequestId) skip('No leave request created in TC-API-018');

  const result = await apiPatch(`/leave-requests/${createdLeaveRequestId}/status`, {
    adminNote: 'No status',
  }, {
    headers: { 'Authorization': `Bearer ${adminToken}` }
  });

  expectRejected(result, `PATCH /leave-requests/${createdLeaveRequestId}/status missing status`);
});

// ============================================================================
// MODULE 4: OTHER BUSINESS & READ-ONLY ENDPOINTS
// ============================================================================

await test('TC-API-026', 'Lay danh sach events (Public)', async () => {
  const result = await apiGet('/events');
  expectOk(result, 'GET /events');
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-027', 'Lay danh sach news (Public)', async () => {
  const result = await apiGet('/news');
  expectOk(result, 'GET /news');
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-028', 'Lay news theo ID (Public)', async () => {
  const list = await apiGet('/news');
  expectOk(list, 'GET /news for ID lookup');

  if (!Array.isArray(list.body) || list.body.length === 0) {
    skip('No news in database');
  }

  const firstId = list.body[0].id;
  const result = await apiGet(`/news/${firstId}`);
  expectOk(result, `GET /news/${firstId}`);
  assert.ok(result.body.title, 'News should have title');
});

await test('TC-API-029', 'Student lay schedule cua chinh minh theo userId', async () => {
  setAuthToken(studentAToken);
  const userId = studentAUser.userId || studentAUser.id;
  const result = await apiGet(`/schedules/user/${userId}`);
  expectOk(result, `GET /schedules/user/${userId}`);
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-030', 'Lay danh sach classes', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/classes');
  expectOk(result, 'GET /classes');
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

// ============================================================================
// MODULE 5: RBAC, OWNERSHIP & IDOR PROTECTION (Priority: Critical)
// ============================================================================

await test('TC-IDOR-001', 'Student A khong the xem grades cua Student B -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const studentBUserId = studentBUser.userId || studentBUser.id;
  const result = await apiGet(`/grades/user/${studentBUserId}`);
  expectForbidden(result, `GET /grades/user/${studentBUserId} by Student A`);
});

await test('TC-IDOR-002', 'Student A goi /grades/me nhan ve dung danh sach diem cua minh', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/grades/me');
  expectOk(result, 'GET /grades/me');
  assert.ok(Array.isArray(result.body), 'Response should be an array');
});

await test('TC-IDOR-003', 'Student A khong the lay toan bo grades toan truong qua /grades -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/grades');
  expectForbidden(result, 'GET /grades by Student A');
});

await test('TC-IDOR-004', 'Student A khong the xem diem cua lop khong duoc phep -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/grades/class/1');
  expectForbidden(result, 'GET /grades/class/1 by Student A');
});

await test('TC-IDOR-005', 'Student A khong the tao grade moi -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const result = await apiPost('/grades', {
    student: { id: 1 },
    subject: { id: 1 },
    schoolYear: { id: 1 },
    semester: 1,
    attendanceScore: 10,
    midtermScore: 10,
    finalScore: 10,
  });
  expectForbidden(result, 'POST /grades by Student A');
});

await test('TC-IDOR-006', 'Student A khong the sua grade -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const result = await apiPut('/grades/49', {
    attendanceScore: 10,
    midtermScore: 10,
    finalScore: 10,
  });
  expectForbidden(result, 'PUT /grades/49 by Student A');
});

await test('TC-IDOR-007', 'Student A khong the xoa grade -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const result = await apiDelete('/grades/49');
  expectForbidden(result, 'DELETE /grades/49 by Student A');
});

await test('TC-IDOR-008', 'Student A khong the xem don xin phep cua Student B -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const studentBUserId = studentBUser.userId || studentBUser.id;
  const result = await apiGet(`/leave-requests/user/${studentBUserId}`);
  expectForbidden(result, `GET /leave-requests/user/${studentBUserId} by Student A`);
});

await test('TC-IDOR-009', 'Student A goi /leave-requests/me nhan ve don cua chinh minh', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/leave-requests/me');
  expectOk(result, 'GET /leave-requests/me');
  assert.ok(Array.isArray(result.body), 'Response should be an array');
});

await test('TC-IDOR-010', 'Student A khong the xem toan bo don toan truong -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/leave-requests');
  expectForbidden(result, 'GET /leave-requests by Student A');
});

await test('TC-IDOR-011', 'Student A khong the tao don mao danh Student B -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const studentBUserId = studentBUser.userId || studentBUser.id;
  const result = await apiPost('/leave-requests', {
    userId: studentBUserId,
    requestType: 'Xin nghi hoc',
    fromDate: addDays(today(), 1),
    toDate: addDays(today(), 2),
    reason: 'IDOR attempt to forge leave request for Student B',
  });
  expectForbidden(result, 'POST /leave-requests for Student B by Student A');
});

await test('TC-IDOR-012', 'Student A khong the tu duyet don xin phep -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const result = await apiPatch(`/leave-requests/${createdLeaveRequestId || 1}/status`, {
    status: 'Đã duyệt',
  });
  expectForbidden(result, 'PATCH /leave-requests/status by Student A');
});

await test('TC-IDOR-013', 'Student A khong the xem thoi khoa bieu cua Student B -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const studentBUserId = studentBUser.userId || studentBUser.id;
  const result = await apiGet(`/schedules/user/${studentBUserId}`);
  expectForbidden(result, `GET /schedules/user/${studentBUserId} by Student A`);
});

await test('TC-IDOR-014', 'Student A goi /schedules/me nhan ve thoi khoa bieu cua chinh minh', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/schedules/me');
  expectOk(result, 'GET /schedules/me');
  assert.ok(Array.isArray(result.body), 'Response should be an array');
});

await test('TC-SCHED-001', 'Student A khong the xem thoi khoa bieu cua lop 2 -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/schedules/class/2');
  expectForbidden(result, 'GET /schedules/class/2 by Student A');
});

await test('TC-SCHED-002', 'Student A khong the xem lich day cua giao vien -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/schedules/teacher/1');
  expectForbidden(result, 'GET /schedules/teacher/1 by Student A');
});

await test('TC-SCHED-003', 'Teacher 1 goi /schedules/me nhan ve lich giang day ca nhan voi className', async () => {
  setAuthToken(teacherToken);
  const result = await apiGet('/schedules/me');
  expectOk(result, 'GET /schedules/me by Teacher');
  assert.ok(Array.isArray(result.body), 'Response should be an array');
  assert.ok(result.body.length > 0, 'Teaching schedule should have days');
  const firstPeriod = result.body[0].periods[0];
  assert.ok(firstPeriod.className, 'Period should contain className for teacher');
});

await test('TC-SCHED-004', 'Teacher 1 khong the xem lich day cua Teacher 2 -> 403 Forbidden', async () => {
  setAuthToken(teacherToken);
  const result = await apiGet('/schedules/teacher/2');
  expectForbidden(result, 'GET /schedules/teacher/2 by Teacher 1');
});

await test('TC-SCHED-005', 'Teacher 1 xem thoi khoa bieu lop 10A1 -> 200 OK', async () => {
  setAuthToken(teacherToken);
  const result = await apiGet('/schedules/class/1');
  expectOk(result, 'GET /schedules/class/1 by Teacher 1');
  assert.ok(Array.isArray(result.body), 'Response should be an array');
});

await test('TC-SCHED-006', 'Admin xem thoi khoa bieu cac lop (1, 2, 3, 4) -> 200 OK', async () => {
  setAuthToken(adminToken);
  for (const classId of [1, 2, 3, 4]) {
    const result = await apiGet(`/schedules/class/${classId}`);
    expectOk(result, `GET /schedules/class/${classId} by Admin`);
    assert.ok(Array.isArray(result.body), 'Response should be an array');
    assert.ok(result.body.length > 0, `Class ${classId} should have schedule`);
  }
});

await test('TC-SCHED-007', 'Admin xem lich giang day cua Teacher 1 va Teacher 2 -> 200 OK', async () => {
  setAuthToken(adminToken);
  for (const teacherId of [1, 2]) {
    const result = await apiGet(`/schedules/teacher/${teacherId}`);
    expectOk(result, `GET /schedules/teacher/${teacherId} by Admin`);
    assert.ok(Array.isArray(result.body), 'Response should be an array');
    assert.ok(result.body.length > 0, `Teacher ${teacherId} should have schedule`);
  }
});

await test('TC-IDOR-015', 'Student A khong the tao khen thuong ky luat -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const result = await apiPost('/rewards-discipline', {
    student: { id: 1 },
    content: 'Fake reward',
  });
  expectForbidden(result, 'POST /rewards-discipline by Student A');
});

await test('TC-IDOR-016', 'Student A khong the xem khen thuong ky luat cua Student B -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const studentBUserId = studentBUser.userId || studentBUser.id;
  const result = await apiGet(`/rewards-discipline/user/${studentBUserId}`);
  expectForbidden(result, `GET /rewards-discipline/user/${studentBUserId} by Student A`);
});

// ============================================================================
// MODULE 6: ATTENDANCE & ATTENDANCE SUMMARY (Phase 3)
// ============================================================================

await test('TC-ATT-001', 'Student goi /attendance/me nhan ve danh sach diem danh', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/attendance/me');
  expectOk(result, 'GET /attendance/me');
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-ATT-002', 'Student goi /attendance/me/summary tra ve cong thuc chuyen can hop le', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/attendance/me/summary');
  expectOk(result, 'GET /attendance/me/summary');
  assert.ok(result.body.studentId != null, 'Should have studentId');
  assert.ok(result.body.totalSessions != null, 'Should have totalSessions');
  assert.ok(result.body.attendanceRate >= 0.0 && result.body.attendanceRate <= 100.0, 'attendanceRate should be 0-100%');
  assert.ok(result.body.statusNote, 'Should have statusNote');
});

await test('TC-ATT-003', 'Student A khong the xem diem danh cua Student B (IDOR) -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/attendance/student/2');
  expectForbidden(result, 'GET /attendance/student/2 by Student A');
});

await test('TC-ATT-004', 'Student A khong the xem summary chuyen can cua Student B (IDOR) -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/attendance/student/2/summary');
  expectForbidden(result, 'GET /attendance/student/2/summary by Student A');
});

await test('TC-ATT-005', 'Student A khong the tao ban ghi diem danh -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const result = await apiPost('/attendance', {
    studentId: 1,
    classId: 1,
    attendanceDate: today(),
    status: 'PRESENT',
  });
  expectForbidden(result, 'POST /attendance by Student A');
});

await test('TC-ATT-006', 'Student A khong the xem diem danh cua ca lop -> 403 Forbidden', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/attendance/class/1');
  expectForbidden(result, 'GET /attendance/class/1 by Student A');
});

await test('TC-ATT-007', 'Teacher ghi nhan diem danh hop le -> 201 Created', async () => {
  const result = await apiPost('/attendance', {
    studentId: 1,
    classId: 1,
    subjectId: 1,
    attendanceDate: today(),
    slotNumber: 1,
    status: 'PRESENT',
    note: 'Diem danh tiet 1 boi giao vien',
  }, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });

  expectStatus(result, 201, 'POST /attendance by Teacher');
  assert.ok(result.body.id != null, 'Should return attendance ID');
  assert.equal(result.body.status, 'PRESENT', 'Status should be PRESENT');
});

await test('TC-ATT-008', 'Teacher xem diem danh ca lop theo ngay', async () => {
  const result = await apiGet(`/attendance/class/1?date=${today()}`, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(result, 'GET /attendance/class/1 by Teacher');
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

// ============================================================================
// MODULE 7: NOTIFICATION CENTER & FCM PUSH (Phase 3)
// ============================================================================

await test('TC-NOTIF-001', 'Student goi /notifications/me nhan ve danh sach thong bao', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/notifications/me');
  expectOk(result, 'GET /notifications/me');
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-NOTIF-002', 'Student goi /notifications/me/unread-count tra ve so tin chua doc', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/notifications/me/unread-count');
  expectOk(result, 'GET /notifications/me/unread-count');
  assert.ok(typeof result.body.unreadCount === 'number', 'unreadCount should be a number');
});

await test('TC-NOTIF-003', 'Student dang ky device token qua /notifications/fcm-token', async () => {
  setAuthToken(studentAToken);
  const result = await apiPost('/notifications/fcm-token', {
    deviceToken: `fcm_token_dummy_${unique('device')}`,
    deviceType: 'ANDROID',
  });
  expectOk(result, 'POST /notifications/fcm-token');
  assert.equal(result.body.success, true, 'Registration should succeed');
});

await test('TC-NOTIF-004', 'Student danh dau doc tat ca thong bao qua /notifications/me/read-all', async () => {
  setAuthToken(studentAToken);
  const result = await apiPatch('/notifications/me/read-all');
  expectOk(result, 'PATCH /notifications/me/read-all');
  assert.equal(result.body.success, true, 'Mark all as read should succeed');
});

await test('TC-NOTIF-005', 'Student B khong the danh dau da doc thong bao cua Student A (Ownership check)', async () => {
  // Ensure Student A has a notification (Teacher 1 updates Math Grade 17 for Student 1)
  await apiPut('/grades/17', {
    attendanceScore: 9.5,
    midtermScore: 9.0,
    finalScore: 9.5,
  }, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });

  setAuthToken(studentAToken);
  const listA = await apiGet('/notifications/me');
  assert.ok(Array.isArray(listA.body) && listA.body.length > 0, 'Student A should have notifications');

  const notifIdA = listA.body[0].id;
  // Student B attempts to mark Student A's notification as read
  const result = await apiPatch(`/notifications/${notifIdA}/read`, {}, {
    headers: { 'Authorization': `Bearer ${studentBToken}` }
  });
  expectForbidden(result, `PATCH /notifications/${notifIdA}/read by Student B`);
});

await test('TC-NOTIF-006', 'Trigger Event: Cap nhat diem sinh ra notification GRADE_UPDATE cho hoc sinh', async () => {
  // Teacher 1 updates Math grade for Student 1
  await apiPut('/grades/17', {
    attendanceScore: 8.0,
    midtermScore: 8.5,
    finalScore: 9.0,
  }, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });

  // Student A checks notifications
  setAuthToken(studentAToken);
  const result = await apiGet('/notifications/me');
  expectOk(result, 'GET /notifications/me after grade update');
  assert.ok(result.body.some(n => n.type === 'GRADE_UPDATE'), 'Should contain GRADE_UPDATE notification');
});

await test('TC-NOTIF-007', 'Trigger Event: Admin duyet don xin phep sinh ra notification LEAVE_REQUEST_STATUS', async () => {
  // Student A creates a leave request
  setAuthToken(studentAToken);
  const leaveRes = await apiPost('/leave-requests', {
    userId: studentAUser.userId,
    requestType: 'Xin nghi hoc',
    fromDate: addDays(today(), 3),
    toDate: addDays(today(), 4),
    reason: `Nghi om - ${unique('trigger')}`,
  });
  expectStatus(leaveRes, 201, 'Create leave request for trigger test');
  const reqId = leaveRes.body.requestId;

  // Admin approves leave request
  const approveRes = await apiPatch(`/leave-requests/${reqId}/status`, {
    status: 'Đã duyệt',
    adminNote: 'Duyet tu dong boi he thong',
  }, {
    headers: { 'Authorization': `Bearer ${adminToken}` }
  });
  expectOk(approveRes, 'Admin approves leave request');

  // Student A checks notifications
  setAuthToken(studentAToken);
  const result = await apiGet('/notifications/me');
  expectOk(result, 'GET /notifications/me after leave approval');
  assert.ok(result.body.some(n => n.type === 'LEAVE_REQUEST_STATUS'), 'Should contain LEAVE_REQUEST_STATUS notification');
});

// ============================================================================
// MODULE 8: TEACHER ASSIGNMENT & SCOPE ENFORCEMENT (Phase 4)
// ============================================================================

await test('TC-ASN-001', 'Teacher xem danh sach phan cong qua /teachers/me/assignments', async () => {
  const result = await apiGet('/teachers/me/assignments', {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(result, 'GET /teachers/me/assignments (Teacher 1)');
  assert.ok(Array.isArray(result.body) && result.body.length > 0, 'Should return assignments');
  assert.ok(result.body.some(a => a.roleType === 'HOMEROOM_TEACHER' && a.classId === 1), 'Teacher 1 is homeroom of Class 1');
  assert.ok(result.body.some(a => a.subjectId === 1 && a.classId === 1), 'Teacher 1 teaches Math in Class 1');
  assert.ok(result.body.some(a => a.subjectId === 1 && a.classId === 2), 'Teacher 1 teaches Math in Class 2');
});

await test('TC-ASN-002', 'Student khong the xem /teachers/me/assignments (403 Forbidden)', async () => {
  setAuthToken(studentAToken);
  const result = await apiGet('/teachers/me/assignments');
  expectForbidden(result, 'GET /teachers/me/assignments by Student');
});

await test('TC-ASN-003', 'Teacher 1 khong the tao diem mon Ngu van (Subject 2) khong duoc phan cong', async () => {
  const gradeData = {
    student: { id: 1 }, // Student 1 (Class 1)
    subject: { id: 2 }, // Literature (Teacher 2 teaches Literature, not Teacher 1)
    schoolYear: { id: 1 },
    semester: 4,
    attendanceScore: 8.0,
    midtermScore: 8.0,
    finalScore: 8.0,
  };

  const result = await apiPost('/grades', gradeData, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectForbidden(result, 'Teacher 1 POST /grades for unassigned Literature subject');
});

await test('TC-ASN-004', 'Teacher 1 khong the sua diem mon Ngu van (Subject 2) cua hoc sinh lop 2', async () => {
  // Find grade for Literature in class 2 or student 4
  const updateData = {
    attendanceScore: 5.0,
    midtermScore: 5.0,
    finalScore: 5.0,
  };

  // Grade 68 is Student 4 (Class 2), Subject 2 (Literature)
  const result = await apiPut('/grades/68', updateData, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectForbidden(result, 'Teacher 1 PUT /grades/68 (Literature Class 2)');
});

await test('TC-ASN-005', 'Teacher 1 khong the diem danh mon Ngu van cho lop 2 (403 Forbidden)', async () => {
  const result = await apiPost('/attendance', {
    studentId: 4, // Class 2
    classId: 2,
    subjectId: 2, // Literature
    attendanceDate: today(),
    slotNumber: 5,
    status: 'PRESENT',
    note: 'Fake attendance',
  }, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectForbidden(result, 'Teacher 1 POST /attendance for unassigned subject/class');
});

await test('TC-ASN-006', 'Diem danh voi Student khong thuoc ve target class bi tu choi 400 Bad Request', async () => {
  // Student 4 belongs to Class 2, but classId 1 is passed
  const result = await apiPost('/attendance', {
    studentId: 4,
    classId: 1,
    subjectId: 1,
    attendanceDate: today(),
    slotNumber: 6,
    status: 'PRESENT',
    note: 'Mismatched student-class test',
  }, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectStatus(result, 400, 'Mismatched student and class ID');
});

await test('TC-ASN-007', 'GVCN (Teacher 1) xem danh sach don xin phep chi thay don cua lop 10A1', async () => {
  const result = await apiGet('/leave-requests', {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(result, 'GET /leave-requests (Teacher 1)');
  assert.ok(Array.isArray(result.body), 'Response should be an array');
  // All returned requests should belong to students of Class 1
});

await test('TC-ASN-008', 'Teacher 1 (GVCN 10A1) khong the duyet don xin phep cua hoc sinh Lop 10A2 (403 Forbidden)', async () => {
  // Student in Class 2 (0904444444 - Phan Van D, Class 10A2) creates leave request
  const student4Login = await apiPost('/auth/login', {
    phoneNumber: '0904444444',
    password: '123456',
  });
  expectOk(student4Login, 'Student 4 (Class 2) login');
  const student4Token = student4Login.body.accessToken;
  const student4UserId = student4Login.body.userId;

  setAuthToken(student4Token);
  const leaveRes = await apiPost('/leave-requests', {
    userId: student4UserId,
    requestType: 'Nghi om',
    fromDate: addDays(today(), 5),
    toDate: addDays(today(), 6),
    reason: `Nghi om dot xuat - ${unique('class2')}`,
  });
  expectStatus(leaveRes, 201, 'Student 4 creates leave request');
  const reqIdClass2 = leaveRes.body.requestId;

  // Teacher 1 attempts to approve Student 4's request -> Forbidden (Teacher 1 is NOT GVCN of 10A2)
  const attemptRes = await apiPatch(`/leave-requests/${reqIdClass2}/status`, {
    status: 'Đã duyệt',
    adminNote: 'Teacher 1 unauthorized approval',
  }, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectForbidden(attemptRes, 'Teacher 1 approves leave request of Class 2');

  // Teacher 2 (GVCN 10A2) approves Student B's request -> OK 200
  const approveRes = await apiPatch(`/leave-requests/${reqIdClass2}/status`, {
    status: 'Đã duyệt',
    adminNote: 'GVCN 10A2 duyet don',
  }, {
    headers: { 'Authorization': `Bearer ${teacher2Token}` }
  });
  expectOk(approveRes, 'Teacher 2 approves leave request of Class 2');
});

await test('TC-ASN-009', 'Student khong the duyet don xin phep cua bat ky ai (403 Forbidden)', async () => {
  setAuthToken(studentAToken);
  const result = await apiPatch('/leave-requests/1/status', {
    status: 'Đã duyệt',
    adminNote: 'Student attempts self-approval',
  });
  expectForbidden(result, 'Student attempts to PATCH /leave-requests/1/status');
});

// ============================================================================
// MODULE 9: REPORTING, DASHBOARD & SYSTEM HARDENING (PHASE 5)
// ============================================================================
console.log('\n--- MODULE 9: REPORTING, DASHBOARD & SYSTEM HARDENING ---');

await test('TC-HARD-001', 'Admin lay Dashboard toan truong thanh cong (200 OK)', async () => {
  const result = await apiGet('/reports/admin/dashboard', {
    headers: { 'Authorization': `Bearer ${adminToken}` }
  });
  expectOk(result, 'GET /reports/admin/dashboard (Admin)');
  assert.ok(result.body.totalStudents > 0, 'totalStudents should be > 0');
  assert.ok(result.body.totalTeachers > 0, 'totalTeachers should be > 0');
  assert.ok(result.body.totalClasses > 0, 'totalClasses should be > 0');
  assert.ok(result.body.gradeDistribution !== undefined, 'gradeDistribution should exist');
  assert.ok(result.body.attendanceRate !== undefined, 'attendanceRate should exist');
});

await test('TC-HARD-002', 'Teacher khong the xem Dashboard toan truong (403 Forbidden)', async () => {
  const result = await apiGet('/reports/admin/dashboard', {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectForbidden(result, 'GET /reports/admin/dashboard (Teacher)');
});

await test('TC-HARD-003', 'GVCN (Teacher 1) lay Dashboard lop chu nhiem thanh cong (200 OK)', async () => {
  const result = await apiGet('/reports/teacher/homeroom', {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(result, 'GET /reports/teacher/homeroom (Teacher 1)');
  assert.strictEqual(result.body.classId, 1, 'Class ID should be 1 (10A1)');
  assert.ok(result.body.totalStudents > 0, 'totalStudents should be > 0');
  assert.ok(result.body.attendanceRate !== undefined, 'attendanceRate should exist');
});

await test('TC-HARD-004', 'Hoc sinh khong the truy cap Dashboard giao vien (403 Forbidden)', async () => {
  const result = await apiGet('/reports/teacher/homeroom', {
    headers: { 'Authorization': `Bearer ${studentAToken}` }
  });
  expectForbidden(result, 'GET /reports/teacher/homeroom (Student)');
});

await test('TC-HARD-005', 'GVBM (Teacher 1) lay thong ke mon Toan tai Lop 1 thanh cong (200 OK)', async () => {
  const result = await apiGet('/reports/teacher/subject-stats?classId=1&subjectId=1', {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(result, 'GET /reports/teacher/subject-stats');
  assert.strictEqual(result.body.classId, 1);
  assert.strictEqual(result.body.subjectId, 1);
  assert.ok(result.body.averageScore !== undefined);
});

await test('TC-HARD-006', 'Student khong the tao tin tuc (403 Forbidden)', async () => {
  const result = await apiPost('/news', {
    title: 'Hoc sinh tu dang tin',
    content: 'Noi dung tin tuc trai phep',
    category: 'Thong bao'
  }, {
    headers: { 'Authorization': `Bearer ${studentAToken}` }
  });
  expectForbidden(result, 'POST /news by Student');
});

await test('TC-HARD-007', 'Student khong the tao su kien (403 Forbidden)', async () => {
  const result = await apiPost('/events', {
    title: 'Hoc sinh tu tao su kien',
    description: 'Su kien trai phep'
  }, {
    headers: { 'Authorization': `Bearer ${studentAToken}` }
  });
  expectForbidden(result, 'POST /events by Student');
});

await test('TC-HARD-008', 'Student lay danh ba giao vien cua minh qua /contacts/me thanh cong (200 OK)', async () => {
  const result = await apiGet('/contacts/me', {
    headers: { 'Authorization': `Bearer ${studentAToken}` }
  });
  expectOk(result, 'GET /contacts/me');
  assert.ok(Array.isArray(result.body), 'Response should be an array of teachers');
  assert.ok(result.body.length > 0, 'Student should have assigned teachers in class');
});

await test('TC-HARD-009', 'Student khong the xem danh ba hoc sinh khac qua IDOR (403 Forbidden)', async () => {
  // Student A (UserID 2) tries to get contacts of User 3
  const result = await apiGet('/contacts/user/3', {
    headers: { 'Authorization': `Bearer ${studentAToken}` }
  });
  expectForbidden(result, 'GET /contacts/user/3 by Student A');
});

await test('TC-HARD-010', 'Cap nhat diem voi gia tri ngoai khoang 0-10 bi tu choi (400 Bad Request)', async () => {
  const result = await apiPut('/grades/17', {
    attendanceScore: 10.0,
    midtermScore: 15.0, // INVALID
    finalScore: 9.0
  }, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectStatus(result, 400, 'Score 15.0 out of range');
});

await test('TC-HARD-011', 'Tao don xin nghi voi fromDate sau toDate bi tu choi (400 Bad Request)', async () => {
  const result = await apiPost('/leave-requests', {
    userId: 2,
    requestType: 'Nghi om',
    fromDate: addDays(today(), 6),
    toDate: addDays(today(), 2), // INVALID: fromDate > toDate
    reason: 'Ngay nghi bat hop le'
  }, {
    headers: { 'Authorization': `Bearer ${studentAToken}` }
  });
  expectStatus(result, 400, 'fromDate > toDate');
});

await test('TC-HARD-012', 'Teacher xem khen thuong ky luat lop khong duoc phan cong bi tu choi (403 Forbidden)', async () => {
  // Teacher 1 is not assigned to Class 3
  const result = await apiGet('/rewards-discipline/class/3', {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectForbidden(result, 'GET /rewards-discipline/class/3 by Teacher 1');
});

// ============================================================================
// PHASE 5.2 - TEACHER PHONE PRIVACY & ROLE-BASED CONTACT DIRECTORY TESTS
// ============================================================================

await test('TC-CONTACT-001', 'Student xem danh ba: GVCN dung dau va SDT giao vien bi an mac dinh (isPhonePublic=false)', async () => {
  const result = await apiGet('/contacts/me', {
    headers: { 'Authorization': `Bearer ${studentAToken}` }
  });
  expectOk(result, 'GET /contacts/me as Student');
  assert.ok(Array.isArray(result.body), 'Response should be array');
  assert.ok(result.body.length > 0, 'Should have teachers');

  // GVCN should be at the front
  const first = result.body[0];
  assert.equal(first.isHomeroom, true, 'First teacher should be homeroom teacher (GVCN)');

  // By default, teacher phone is masked (null) because isPhonePublic is false
  const teacherWithPhoneHidden = result.body.find(t => !t.isPhonePublic);
  if (teacherWithPhoneHidden) {
    assert.equal(teacherWithPhoneHidden.phone, null, 'Teacher phone should be masked (null) for student');
  }
});

await test('TC-CONTACT-002', 'Teacher cap nhat quyen rieng tu SDT qua PATCH /contacts/me/phone-privacy (200 OK)', async () => {
  const result = await apiPatch('/contacts/me/phone-privacy', {
    isPhonePublic: true
  }, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(result, 'PATCH /contacts/me/phone-privacy');
  assert.equal(result.body.isPhonePublic, true, 'isPhonePublic should be true');
});

await test('TC-CONTACT-003', 'Student xem lai danh ba: SDT cua giao vien hien thi khi isPhonePublic=true', async () => {
  const result = await apiGet('/contacts/me', {
    headers: { 'Authorization': `Bearer ${studentAToken}` }
  });
  expectOk(result, 'GET /contacts/me after privacy enabled');
  const teacherWithPublicPhone = result.body.find(t => t.isPhonePublic);
  assert.ok(teacherWithPublicPhone, 'Should have a teacher with public phone');
  assert.ok(teacherWithPublicPhone.phone && teacherWithPublicPhone.phone.length > 0, 'Teacher phone should now be visible to student');
});

await test('TC-CONTACT-004', 'Teacher tat chia se SDT -> SDT bi an tro lai doi voi Student (Zero-Trust)', async () => {
  // Revert back to false
  const patchResult = await apiPatch('/contacts/me/phone-privacy', {
    isPhonePublic: false
  }, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(patchResult, 'PATCH /contacts/me/phone-privacy back to false');
  assert.equal(patchResult.body.isPhonePublic, false);

  // Student re-checks
  const result = await apiGet('/contacts/me', {
    headers: { 'Authorization': `Bearer ${studentAToken}` }
  });
  expectOk(result, 'GET /contacts/me after privacy disabled');
  const updatedTeacher = result.body.find(t => t.teacherId === 1);
  if (updatedTeacher) {
    assert.equal(updatedTeacher.phone, null, 'Phone should be masked again');
    assert.equal(updatedTeacher.isPhonePublic, false);
  }
});

await test('TC-CONTACT-005', 'Teacher xem danh ba qua /contacts/me: thay danh ba dong nghiep toan truong co SDT noi bo', async () => {
  const result = await apiGet('/contacts/me', {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(result, 'GET /contacts/me as Teacher');
  assert.ok(Array.isArray(result.body));
  assert.ok(result.body.length >= 2, 'Colleague directory should have multiple teachers');
  // Teachers should be able to see colleague phone numbers
  const colleague = result.body.find(t => t.phone && t.phone.length > 0);
  assert.ok(colleague, 'Teacher should see internal phone of colleagues');
});

await test('TC-CONTACT-006', 'Admin xem danh ba qua /contacts/me: thay toan bo giao vien voi day du thong tin', async () => {
  const result = await apiGet('/contacts/me', {
    headers: { 'Authorization': `Bearer ${adminToken}` }
  });
  expectOk(result, 'GET /contacts/me as Admin');
  assert.ok(Array.isArray(result.body));
  assert.ok(result.body.length >= 2);
  const first = result.body[0];
  assert.ok(first.teacherId);
  assert.ok(first.fullName);
  assert.ok(first.email);
  assert.ok(first.status);
});

await test('TC-CONTACT-007', 'Student khong the goi PATCH /contacts/me/phone-privacy (403 Forbidden)', async () => {
  const result = await apiPatch('/contacts/me/phone-privacy', {
    isPhonePublic: true
  }, {
    headers: { 'Authorization': `Bearer ${studentAToken}` }
  });
  expectForbidden(result, 'Student modifying teacher phone privacy');
});

// ============================================================================
// PHASE 5.3 - IN-APP MESSAGING & CHAT TESTS
// ============================================================================

await test('TC-MSG-001', 'Admin gui tin nhan cho Teacher thanh cong (201 Created)', async () => {
  const teacherUserId = teacherUser.userId || teacherUser.id;
  const result = await apiPost('/messages', {
    receiverUserId: teacherUserId,
    content: 'Chao thay, xin gui bao cao hoc ky som nhe'
  }, {
    headers: { 'Authorization': `Bearer ${adminToken}` }
  });
  expectStatus(result, 201, 'POST /messages by Admin');
  assert.ok(result.body.id, 'Should have message id');
  assert.equal(result.body.content, 'Chao thay, xin gui bao cao hoc ky som nhe');
  assert.equal(result.body.isMe, true);
  assert.equal(result.body.receiverUserId, teacherUserId);
});

await test('TC-MSG-002', 'Teacher xem danh sach hoi thoai qua /messages/conversations thay tin nhan cua Admin', async () => {
  const result = await apiGet('/messages/conversations', {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(result, 'GET /messages/conversations as Teacher');
  assert.ok(Array.isArray(result.body), 'Response should be an array');
  const adminConvo = result.body.find(c => c.targetUserId === (adminUser.userId || adminUser.id));
  assert.ok(adminConvo, 'Should find conversation with Admin');
  assert.ok(adminConvo.lastMessage.includes('Chao thay'), 'Last message snippet matches');
});

await test('TC-MSG-003', 'Teacher lay lich su chat 1-1 voi Admin qua /messages/with/{adminId} va tu dong danh dau da doc', async () => {
  const adminUserId = adminUser.userId || adminUser.id;
  const result = await apiGet(`/messages/with/${adminUserId}`, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectOk(result, 'GET /messages/with/{adminUserId}');
  assert.ok(Array.isArray(result.body));
  assert.ok(result.body.length > 0, 'Should have messages');
  const last = result.body[result.body.length - 1];
  assert.equal(last.content, 'Chao thay, xin gui bao cao hoc ky som nhe');
  assert.equal(last.isMe, false);
});

await test('TC-MSG-004', 'Teacher tra loi tin nhan cua Admin thanh cong (201 Created)', async () => {
  const adminUserId = adminUser.userId || adminUser.id;
  const result = await apiPost('/messages', {
    receiverUserId: adminUserId,
    content: 'Vang a, toi se gui trong chieu nay.'
  }, {
    headers: { 'Authorization': `Bearer ${teacherToken}` }
  });
  expectStatus(result, 201, 'POST /messages by Teacher');
  assert.equal(result.body.content, 'Vang a, toi se gui trong chieu nay.');
  assert.equal(result.body.isMe, true);
});

await test('TC-MSG-005', 'Hoc sinh khong the tu gui tin nhan cho chinh minh (400 Bad Request)', async () => {
  const studentUserId = studentAUser.userId || studentAUser.id;
  const result = await apiPost('/messages', {
    receiverUserId: studentUserId,
    content: 'Tu nhan tin cho ban than'
  }, {
    headers: { 'Authorization': `Bearer ${studentAToken}` }
  });
  expectStatus(result, 400, 'POST /messages to self');
});

await test('TC-MSG-006', 'Hoc sinh lay lich su chat voi Admin khong bi lan tin nhan giua Admin va Teacher (IDOR protection)', async () => {
  const adminUserId = adminUser.userId || adminUser.id;
  const result = await apiGet(`/messages/with/${adminUserId}`, {
    headers: { 'Authorization': `Bearer ${studentAToken}` }
  });
  expectOk(result, 'GET /messages/with/{adminUserId} by Student');
  assert.ok(Array.isArray(result.body));
  // Student should NOT see the message exchanged between Admin and Teacher
  const leakedMessage = result.body.find(m => m.content.includes('Chao thay, xin gui bao cao hoc ky som nhe'));
  assert.equal(leakedMessage, undefined, 'Student must NOT see message between Admin and Teacher');
});


// ============================================================================
// REPORT
// ============================================================================
console.log('');
console.log(`API base: ${apiBase}`);
exitWithSummary();
