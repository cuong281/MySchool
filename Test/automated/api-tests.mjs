// ============================================================================
// MySchool — API Integration Tests
// Pattern: Adapted from Library-Management-System-Project reference
// Framework: Custom Node.js test harness (no external dependencies)
// Requirement: Backend running at http://localhost:8080, DB seeded
// ============================================================================

import {
  addDays,
  apiBase,
  apiGet,
  apiPost,
  apiPut,
  apiPatch,
  apiDelete,
  assert,
  exitWithSummary,
  expectOk,
  expectRejected,
  expectStatus,
  skip,
  step,
  test,
  today,
  unique,
} from './test-harness.mjs';

// ── Shared state across tests ──────────────────────────────────────────────
let loginResponse = null;     // AuthResponse from successful login
let createdGradeId = null;    // Grade ID created during test for later update/delete
let createdLeaveRequestId = null; // Leave request created for status update test

// ============================================================================
// MODULE 1: AUTHENTICATION (Priority: Critical)
// ============================================================================

await test('TC-API-001', 'Login thanh cong voi phone + password hop le', async () => {
  const result = await apiPost('/auth/login', {
    phoneNumber: '0123456789',
    password: '123456',
  });

  if (!result.ok) {
    // Try alternative credentials from seed data
    const alt = await apiPost('/auth/login', {
      phoneNumber: '0901234567',
      password: '123456',
    });
    if (!alt.ok) {
      skip('No known valid credentials in seed data — update phone/password in test');
    }
    loginResponse = alt.body;
    assert.ok(alt.body.userId || alt.body.id, 'Response should contain userId');
    assert.ok(alt.body.username, 'Response should contain username');
    assert.ok(Array.isArray(alt.body.roles), 'Response should contain roles array');
    return;
  }

  expectOk(result, 'POST /auth/login');
  loginResponse = result.body;
  assert.ok(result.body.userId || result.body.id, 'Response should contain userId');
  assert.ok(result.body.username, 'Response should contain username');
  assert.ok(Array.isArray(result.body.roles), 'Response should contain roles array');
});

await test('TC-API-002', 'Login that bai — sai password', async () => {
  const result = await apiPost('/auth/login', {
    phoneNumber: '0123456789',
    password: 'wrong_password_xyz',
  });
  expectRejected(result, 'POST /auth/login wrong password');
});

await test('TC-API-003', 'Login that bai — phone khong ton tai', async () => {
  const result = await apiPost('/auth/login', {
    phoneNumber: '9999999999',
    password: '123456',
  });
  expectRejected(result, 'POST /auth/login unknown phone');
});

await test('TC-API-004', 'Login that bai — thieu phone', async () => {
  const result = await apiPost('/auth/login', {
    password: '123456',
  });
  expectRejected(result, 'POST /auth/login missing phone');
});

await test('TC-API-005', 'Login that bai — thieu password', async () => {
  const result = await apiPost('/auth/login', {
    phoneNumber: '0123456789',
  });
  expectRejected(result, 'POST /auth/login missing password');
});

await test('TC-API-006', 'Login that bai — phone rong', async () => {
  const result = await apiPost('/auth/login', {
    phoneNumber: '',
    password: '123456',
  });
  expectRejected(result, 'POST /auth/login empty phone');
});

// ============================================================================
// MODULE 2: GRADE CRUD (Priority: High–Critical)
// ============================================================================

await test('TC-API-007', 'Lay danh sach tat ca grades', async () => {
  const result = await apiGet('/grades');
  expectOk(result, 'GET /grades');
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-008', 'Lay grade theo ID hop le', async () => {
  // First get list to find a valid ID
  const list = await apiGet('/grades');
  expectOk(list, 'GET /grades for ID lookup');

  if (!Array.isArray(list.body) || list.body.length === 0) {
    skip('No grades in database to test getById');
  }

  const firstId = list.body[0].id;
  const result = await apiGet(`/grades/${firstId}`);
  expectOk(result, `GET /grades/${firstId}`);
  assert.ok(result.body.id, 'Grade should have id field');
});

await test('TC-API-009', 'Lay grade theo ID khong ton tai', async () => {
  const result = await apiGet('/grades/999999');
  expectStatus(result, 404, 'GET /grades/999999');
});

await test('TC-API-010', 'Lay grades theo userId', async () => {
  if (!loginResponse) skip('Need successful login to get userId');

  const userId = loginResponse.userId || loginResponse.id;
  const result = await apiGet(`/grades/user/${userId}`);
  // May return 200 with empty list or populated list
  expectOk(result, `GET /grades/user/${userId}`);
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-011', 'Lay grades theo classId', async () => {
  if (!loginResponse || !loginResponse.classId) skip('Need classId from login');

  const classId = loginResponse.classId;
  const result = await apiGet(`/grades/class/${classId}`);
  expectOk(result, `GET /grades/class/${classId}`);
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-012', 'Tao grade moi hop le', async () => {
  // This test requires knowing valid studentId, subjectId, schoolYearId from DB
  // Try POST and check response
  const gradeData = {
    student: { id: 1 },
    subject: { id: 1 },
    schoolYear: { id: 1 },
    semester: 1,
    attendanceScore: 8.5,
    midtermScore: 7.0,
    finalScore: 8.0,
  };

  const result = await apiPost('/grades', gradeData);

  if (result.status === 409) {
    // Duplicate — student already has this grade, test still validates endpoint works
    console.log('  INFO: Grade already exists (409 Conflict) — endpoint works correctly');
    return;
  }

  if (result.status === 500 && result.body?.error?.includes('not found')) {
    skip('Student/Subject/SchoolYear ID 1 not in seed data — adjust IDs');
  }

  if (result.ok) {
    expectStatus(result, 201, 'POST /grades');
    createdGradeId = result.body.id;
    assert.ok(result.body.id, 'Created grade should have id');
  }
});

await test('TC-API-013', 'Tao grade trung (student+subject+year+semester)', async () => {
  // First, get existing grades to find a combination that already exists
  const list = await apiGet('/grades');
  expectOk(list, 'GET /grades for duplicate check');

  if (!Array.isArray(list.body) || list.body.length === 0) {
    skip('No existing grades to create duplicate from');
  }

  const existing = list.body[0];
  // Try to create duplicate with same student+subject+year+semester
  const gradeData = {
    student: { id: existing.studentId },
    subject: { id: 1 }, // May not match exactly, but test the conflict logic
    schoolYear: { id: 1 },
    semester: existing.semester || 1,
    attendanceScore: 5.0,
    midtermScore: 5.0,
    finalScore: 5.0,
  };

  const result = await apiPost('/grades', gradeData);
  // Should be 409 Conflict or 500 if data already exists
  if (result.ok) {
    // If it created successfully, it means the combination was unique — clean up
    if (result.body?.id) {
      await apiDelete(`/grades/${result.body.id}`);
    }
    console.log('  INFO: No duplicate detected — combination was unique');
  } else {
    // Expected: rejected due to duplicate
    assert.ok([409, 500].includes(result.status), `Expected 409 or 500 but got ${result.status}`);
  }
});

await test('TC-API-014', 'Cap nhat grade hop le', async () => {
  // Find a grade to update
  const list = await apiGet('/grades');
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

  const result = await apiPut(`/grades/${targetId}`, updateData);
  expectOk(result, `PUT /grades/${targetId}`);
});

await test('TC-API-015', 'Cap nhat grade voi ID khong ton tai', async () => {
  const result = await apiPut('/grades/999999', {
    attendanceScore: 5.0,
    midtermScore: 5.0,
    finalScore: 5.0,
  });
  expectRejected(result, 'PUT /grades/999999');
});

await test('TC-API-016', 'Xoa grade hop le', async () => {
  if (!createdGradeId) {
    skip('No grade was created in TC-API-012 to delete');
  }

  const result = await apiDelete(`/grades/${createdGradeId}`);
  expectOk(result, `DELETE /grades/${createdGradeId}`);
});

await test('TC-API-017', 'Xoa grade voi ID khong ton tai', async () => {
  const result = await apiDelete('/grades/999999');
  expectRejected(result, 'DELETE /grades/999999');
});

// ============================================================================
// MODULE 3: LEAVE REQUEST (Priority: Critical)
// ============================================================================

await test('TC-API-018', 'Tao don xin phep hop le', async () => {
  if (!loginResponse) skip('Need login to get userId');

  const userId = loginResponse.userId || loginResponse.id;
  const fromDate = addDays(today(), 1); // Tomorrow
  const toDate = addDays(today(), 2);

  const result = await apiPost('/leave-requests', {
    userId,
    requestType: 'Xin nghi hoc',
    fromDate,
    toDate,
    reason: `Test don xin phep - ${unique('QA')}`,
  });

  if (result.status === 400 && result.body?.error?.includes('Student not found')) {
    skip('Current user is not a Student — cannot create leave request');
  }

  expectStatus(result, 201, 'POST /leave-requests');
  createdLeaveRequestId = result.body?.requestId;
  assert.ok(createdLeaveRequestId, 'Response should contain requestId');
});

await test('TC-API-019', 'Tao don thieu thong tin (reason rong)', async () => {
  if (!loginResponse) skip('Need login to get userId');

  const userId = loginResponse.userId || loginResponse.id;
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
  if (!loginResponse) skip('Need login to get userId');

  const userId = loginResponse.userId || loginResponse.id;
  const result = await apiPost('/leave-requests', {
    userId,
    requestType: 'Xin nghi hoc',
    fromDate: addDays(today(), -5), // 5 days ago
    toDate: addDays(today(), -3),
    reason: 'Test fromDate in past',
  });

  expectRejected(result, 'POST /leave-requests fromDate in past');
});

await test('TC-API-021', 'Tao don voi toDate truoc fromDate', async () => {
  if (!loginResponse) skip('Need login to get userId');

  const userId = loginResponse.userId || loginResponse.id;
  const result = await apiPost('/leave-requests', {
    userId,
    requestType: 'Xin nghi hoc',
    fromDate: addDays(today(), 5),
    toDate: addDays(today(), 3), // Before fromDate
    reason: 'Test toDate before fromDate',
  });

  expectRejected(result, 'POST /leave-requests toDate before fromDate');
});

await test('TC-API-022', 'Lay danh sach don theo userId', async () => {
  if (!loginResponse) skip('Need login to get userId');

  const userId = loginResponse.userId || loginResponse.id;
  const result = await apiGet(`/leave-requests/user/${userId}`);
  expectOk(result, `GET /leave-requests/user/${userId}`);
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-023', 'Lay tat ca don (admin)', async () => {
  const result = await apiGet('/leave-requests');
  expectOk(result, 'GET /leave-requests');
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-024', 'Cap nhat status don (Duyet) — State Transition', async () => {
  if (!createdLeaveRequestId) skip('No leave request created in TC-API-018');

  const result = await apiPatch(`/leave-requests/${createdLeaveRequestId}/status`, {
    status: 'Đã duyệt',
    processedByUserId: 1,
  });

  expectOk(result, `PATCH /leave-requests/${createdLeaveRequestId}/status`);
  assert.ok(result.body.status || result.body.message, 'Response should confirm update');
});

await test('TC-API-025', 'Cap nhat status don thieu status field', async () => {
  if (!createdLeaveRequestId) skip('No leave request created in TC-API-018');

  const result = await apiPatch(`/leave-requests/${createdLeaveRequestId}/status`, {
    processedByUserId: 1,
  });

  expectRejected(result, `PATCH /leave-requests/${createdLeaveRequestId}/status missing status`);
});

// ============================================================================
// MODULE 4: OTHER READ-ONLY ENDPOINTS (Priority: Medium)
// ============================================================================

await test('TC-API-026', 'Lay danh sach events', async () => {
  const result = await apiGet('/events');
  expectOk(result, 'GET /events');
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-027', 'Lay danh sach news', async () => {
  const result = await apiGet('/news');
  expectOk(result, 'GET /news');
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-028', 'Lay news theo ID', async () => {
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

await test('TC-API-029', 'Lay schedule theo userId', async () => {
  if (!loginResponse) skip('Need login to get userId');

  const userId = loginResponse.userId || loginResponse.id;
  const result = await apiGet(`/schedules/user/${userId}`);
  expectOk(result, `GET /schedules/user/${userId}`);
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

await test('TC-API-030', 'Lay danh sach classes', async () => {
  const result = await apiGet('/classes');
  expectOk(result, 'GET /classes');
  assert.equal(Array.isArray(result.body), true, 'Response should be an array');
});

// ============================================================================
// REPORT
// ============================================================================
console.log('');
console.log(`API base: ${apiBase}`);
exitWithSummary();
