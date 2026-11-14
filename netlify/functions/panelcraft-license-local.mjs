const TEST_KEY = 'PC21-LOCAL-TEST';
const TEST_PHONE = '919999999999';
const TEST_TOKEN = 'PANELCRAFT_LOCAL_TEST_SESSION';

function normalizePhone(value) {
  let digits = String(value ?? '').replace(/[^0-9]/g, '');
  if (digits.length === 10) digits = '91' + digits;
  return digits;
}

function allowedDevelopmentHost(request) {
  const forwarded = request.headers.get('x-forwarded-host')
    || request.headers.get('host')
    || new URL(request.url).hostname;
  const host = String(forwarded).split(',')[0].trim().replace(/:\d+$/, '').toLowerCase();
  if (host === 'localhost' || host.endsWith('.localhost') || host === '::1' || host.endsWith('.trycloudflare.com')) return true;
  const p = host.split('.').map(Number);
  if (p.length !== 4 || p.some(n => !Number.isInteger(n) || n < 0 || n > 255)) return false;
  return p[0] === 10
    || p[0] === 127
    || (p[0] === 192 && p[1] === 168)
    || (p[0] === 172 && p[1] >= 16 && p[1] <= 31)
    || (p[0] === 169 && p[1] === 254);
}

function respond(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store, no-cache, must-revalidate',
      'X-Content-Type-Options': 'nosniff',
    },
  });
}

export default async function handler(request) {
  // This mock endpoint is deliberately unavailable on public production hostnames.
  if (!allowedDevelopmentHost(request)) {
    return respond({ ok: false, code: 'NOT_FOUND', message: 'Local test licensing is available only from a local development host.' }, 404);
  }

  if (request.method === 'OPTIONS') return new Response(null, { status: 204 });
  if (request.method !== 'POST') return respond({ ok: false, code: 'METHOD_NOT_ALLOWED', message: 'Use POST.' }, 405);

  let payload;
  try {
    payload = await request.json();
  } catch {
    return respond({ ok: false, code: 'INVALID_JSON', message: 'Request body must be valid JSON.' }, 400);
  }

  const action = String(payload?.action || '').toLowerCase();
  if (action === 'activate') {
    const key = String(payload?.licenseKey || '').trim().toUpperCase();
    const phone = normalizePhone(payload?.phone);
    if (key !== TEST_KEY) {
      return respond({ ok: false, code: 'INVALID_LICENSE', message: 'Use the local test key shown on this development login screen.' }, 401);
    }
    if (phone !== TEST_PHONE) {
      return respond({ ok: false, code: 'INVALID_PHONE', message: 'Use the local test phone number shown on this development login screen.' }, 400);
    }
    return respond({
      ok: true,
      token: TEST_TOKEN,
      licenseKey: TEST_KEY,
      phoneLast4: TEST_PHONE.slice(-4),
      userId: 'LOCAL-TEST',
      expiresAt: null,
      sessionExpiresAt: Date.now() + 30 * 24 * 60 * 60 * 1000,
      localTest: true,
    });
  }

  if (action === 'verify') {
    if (payload?.token !== TEST_TOKEN) {
      return respond({ ok: false, code: 'SESSION_INVALID', message: 'Local test session is invalid. Enter the local test credentials again.' }, 401);
    }
    return respond({
      ok: true,
      token: TEST_TOKEN,
      licenseKey: TEST_KEY,
      phoneLast4: TEST_PHONE.slice(-4),
      userId: 'LOCAL-TEST',
      expiresAt: null,
      sessionExpiresAt: Date.now() + 30 * 24 * 60 * 60 * 1000,
      localTest: true,
    });
  }

  return respond({ ok: false, code: 'INVALID_ACTION', message: 'Unsupported local license action.' }, 400);
}
