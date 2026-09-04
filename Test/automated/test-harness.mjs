import assert from 'node:assert/strict';

// ── Configuration ──────────────────────────────────────────────────────────
export const apiBase = process.env.API_BASE_URL || 'http://localhost:8080/api';

// ── Auth Token State ───────────────────────────────────────────────────────
let currentAuthToken = null;

export function setAuthToken(token) {
  currentAuthToken = token;
}

export function getAuthToken() {
  return currentAuthToken;
}

export function clearAuthToken() {
  currentAuthToken = null;
}

export async function loginAs(phoneNumber, password) {
  const res = await apiPost('/auth/login', { phoneNumber, password });
  if (res.ok && res.body?.accessToken) {
    setAuthToken(res.body.accessToken);
  }
  return res;
}

// ── Test Result Tracking ───────────────────────────────────────────────────
const results = [];

export async function test(id, title, fn) {
  const startedAt = Date.now();
  console.log(`RUN  ${id} - ${title}`);
  try {
    await fn();
    results.push({ id, title, status: 'PASS', durationMs: Date.now() - startedAt });
    console.log(`PASS ${id} - ${title}`);
  } catch (error) {
    if (error?.name === 'SkipTest') {
      results.push({ id, title, status: 'SKIP', reason: error.message, durationMs: Date.now() - startedAt });
      console.log(`SKIP ${id} - ${title}: ${error.message}`);
      return;
    }
    results.push({ id, title, status: 'FAIL', reason: error?.message || String(error), durationMs: Date.now() - startedAt });
    console.error(`FAIL ${id} - ${title}`);
    console.error(`     ${error?.message || error}`);
  }
}

export async function step(message, fn) {
  console.log(`  STEP ${message}`);
  return fn();
}

export function skip(message) {
  const error = new Error(message);
  error.name = 'SkipTest';
  throw error;
}

// ── Summary & Exit ─────────────────────────────────────────────────────────
export function summary() {
  const counts = results.reduce(
    (acc, item) => {
      acc[item.status] += 1;
      return acc;
    },
    { PASS: 0, FAIL: 0, SKIP: 0 },
  );

  console.log('');
  console.log('='.repeat(60));
  console.log(`Summary: ${counts.PASS} passed, ${counts.FAIL} failed, ${counts.SKIP} skipped`);
  console.log('='.repeat(60));

  if (counts.FAIL > 0) {
    console.log('');
    console.log('Failed tests:');
    results
      .filter((r) => r.status === 'FAIL')
      .forEach((r) => console.log(`  ✗ ${r.id} - ${r.title}: ${r.reason}`));
  }

  return { counts, results };
}

export function exitWithSummary() {
  const { counts } = summary();
  if (counts.FAIL > 0) {
    process.exitCode = 1;
  }
}

// ── HTTP Helpers ───────────────────────────────────────────────────────────
function buildHeaders(customHeaders = {}) {
  const headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...customHeaders,
  };
  if (currentAuthToken && customHeaders['Authorization'] === undefined) {
    headers['Authorization'] = `Bearer ${currentAuthToken}`;
  }
  if (headers['Authorization'] === '') {
    delete headers['Authorization'];
  }
  return headers;
}

export async function apiGet(path, options = {}) {
  const headers = buildHeaders(options.headers);
  const response = await fetch(`${apiBase}${path}`, {
    method: 'GET',
    headers,
  });
  return parseResponse(response);
}

export async function apiPost(path, body, options = {}) {
  const headers = buildHeaders(options.headers);
  const response = await fetch(`${apiBase}${path}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });
  return parseResponse(response);
}

export async function apiPut(path, body, options = {}) {
  const headers = buildHeaders(options.headers);
  const response = await fetch(`${apiBase}${path}`, {
    method: 'PUT',
    headers,
    body: JSON.stringify(body),
  });
  return parseResponse(response);
}

export async function apiPatch(path, body, options = {}) {
  const headers = buildHeaders(options.headers);
  const response = await fetch(`${apiBase}${path}`, {
    method: 'PATCH',
    headers,
    body: JSON.stringify(body),
  });
  return parseResponse(response);
}

export async function apiDelete(path, options = {}) {
  const headers = buildHeaders(options.headers);
  const response = await fetch(`${apiBase}${path}`, {
    method: 'DELETE',
    headers,
  });
  return parseResponse(response);
}

export async function parseResponse(response) {
  const text = await response.text();
  let body = null;
  if (text) {
    try {
      body = JSON.parse(text);
    } catch {
      body = text;
    }
  }
  return { ok: response.ok, status: response.status, body, text };
}

// ── Assertion Helpers ──────────────────────────────────────────────────────
export function expectOk(result, context) {
  assert.equal(result.ok, true, `${context} expected HTTP 2xx but got ${result.status}: ${result.text}`);
}

export function expectRejected(result, context) {
  assert.equal(result.ok, false, `${context} expected HTTP non-2xx but got ${result.status}`);
}

export function expectStatus(result, expectedStatus, context) {
  assert.equal(result.status, expectedStatus, `${context} expected HTTP ${expectedStatus} but got ${result.status}: ${result.text}`);
}

// ── Date Helpers ───────────────────────────────────────────────────────────
export function today() {
  return new Date().toISOString().slice(0, 10);
}

export function addDays(dateText, days) {
  const date = new Date(`${dateText}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

// ── Unique ID Helper ───────────────────────────────────────────────────────
export function unique(prefix) {
  return `${prefix}-${Date.now()}-${Math.floor(Math.random() * 100000)}`;
}

export { assert };
