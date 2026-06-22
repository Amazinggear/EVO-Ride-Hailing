#!/usr/bin/env node
// Simple benchmark script - tests all critical admin API endpoints
const API = 'https://evo-backend-5zsg.onrender.com';
let token = '';
let totalTests = 0;
let passed = 0;
let failed = 0;
let errors = [];

async function test(name, url, options = {}, expectedStatus = 200) {
  totalTests++;
  try {
    const opts = {
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(options.headers || {}),
      },
      ...options,
    };
    if (opts.body && typeof opts.body === 'object') opts.body = JSON.stringify(opts.body);
    
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
    const start = Date.now();
    const res = await fetch(url, { ...opts, signal: controller.signal });
    clearTimeout(timeout);
    const ms = Date.now() - start;
    
    const data = await res.json().catch(() => ({}));
    const statusOk = res.status === expectedStatus;
    
    if (statusOk) {
      passed++;
      console.log(`  ✅ ${name} (${ms}ms)`);
    } else {
      failed++;
      const err = { name, url, expected: expectedStatus, got: res.status, body: JSON.stringify(data).substring(0, 200) };
      errors.push(err);
      console.log(`  ❌ ${name}: expected ${expectedStatus}, got ${res.status} — ${JSON.stringify(data).substring(0, 100)}`);
    }
    return { ok: statusOk, data, ms };
  } catch (err) {
    failed++;
    const errObj = { name, url, error: err.message };
    errors.push(errObj);
    console.log(`  ❌ ${name}: ${err.message}`);
    return { ok: false, error: err.message };
  }
}

(async () => {
  const startTime = Date.now();
  
  console.log('\n🔬 EVO Benchmark —', new Date().toISOString());
  console.log('═══════════════════════════════════════\n');

  // 1. Health Check
  console.log('1️⃣  HEALTH');
  await test('Health check', `${API}/health`);

  // 2. Auth
  console.log('\n2️⃣  AUTH');
  const loginRes = await test('Login admin', `${API}/api/v1/admin/login`, {
    method: 'POST', body: { email: 'admin@evo.jo', password: '123456' }
  });
  if (loginRes.ok) token = loginRes.data.accessToken;
  await test('Login wrong password', `${API}/api/v1/admin/login`, {
    method: 'POST', body: { email: 'admin@evo.jo', password: 'wrong' }
  }, 401);

  if (!token) {
    console.log('\n❌ Cannot proceed without auth token');
    process.exit(1);
  }

  // 3. Dashboard
  console.log('\n3️⃣  DASHBOARD');
  await test('Dashboard stats', `${API}/api/v1/admin/dashboard/stats`);
  await test('Staff metrics', `${API}/api/v1/admin/staff-metrics`);

  // 4. Users / Customers
  console.log('\n4️⃣  CUSTOMERS');
  await test('List users', `${API}/api/v1/admin/users`);
  await test('Filter users by role', `${API}/api/v1/admin/users?role=passenger`);

  // 5. Drivers
  console.log('\n5️⃣  DRIVERS');
  await test('List drivers', `${API}/api/v1/admin/drivers`);
  await test('Pending drivers', `${API}/api/v1/admin/drivers/pending`);

  // 6. Rides
  console.log('\n6️⃣  RIDES');
  await test('List rides', `${API}/api/v1/admin/rides`);
  await test('Live rides', `${API}/api/v1/admin/rides/live`);

  // 7. Pricing
  console.log('\n7️⃣  PRICING');
  await test('Get pricing', `${API}/api/v1/admin/pricing`);

  // 8. Promos
  console.log('\n8️⃣  PROMOS');
  await test('List promos', `${API}/api/v1/admin/promo-codes`);

  // 9. Wallets
  console.log('\n9️⃣  WALLETS');
  await test('Wallet balances', `${API}/api/v1/admin/wallet/balances`);

  // 10. Financial
  console.log('\n🔟  FINANCIAL');
  await test('Financial summary', `${API}/api/v1/admin/financials/summary`);
  await test('Transactions', `${API}/api/v1/admin/financials/transactions`);

  // 11. Complaints
  console.log('\n1️⃣1️⃣  COMPLAINTS');
  await test('List complaints', `${API}/api/v1/admin/complaints`);

  // 12. Audit
  console.log('\n1️⃣2️⃣  AUDIT');
  await test('Audit logs', `${API}/api/v1/admin/audit-logs`);

  // 13. System logs
  console.log('\n1️⃣3️⃣  SYSTEM LOGS');
  await test('System logs', `${API}/api/v1/admin/system-logs`);

  // 14. RBAC Tests
  console.log('\n1️⃣4️⃣  RBAC TESTS');
  // Login as support
  const supportRes = await fetch(`${API}/api/v1/admin/login`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'hassan@evo.jo', password: '123456' })
  });
  if (supportRes.ok) {
    const supportData = await supportRes.json();
    const supportToken = supportData.accessToken;
    const supportHeaders = { Authorization: `Bearer ${supportToken}`, 'Content-Type': 'application/json' };
    
    await test('Support CAN list complaints', `${API}/api/v1/admin/complaints`, { headers: supportHeaders });
    await test('Support CANNOT list promos', `${API}/api/v1/admin/promo-codes`, { headers: supportHeaders }, 403);
    await test('Support CANNOT access pricing', `${API}/api/v1/admin/pricing`, { headers: supportHeaders }, 403);
    await test('Support CANNOT access wallets', `${API}/api/v1/admin/wallet/balances`, { headers: supportHeaders }, 403);
  } else {
    console.log('  ⚠️ Support user (hassan@evo.jo) not found — RBAC tests skipped');
  }

  // 15. Security
  console.log('\n1️⃣5️⃣  SECURITY');
  await test('No token — 401', `${API}/api/v1/admin/drivers`, {}, 401);
  await test('Invalid token — 401', `${API}/api/v1/admin/drivers`, {
    headers: { Authorization: 'Bearer invalid_token_xyz' }
  }, 401);

  // 16. CRUD test
  console.log('\n1️⃣6️⃣  CRUD CYCLE');
  // Create test admin
  const createRes = await test('Create admin', `${API}/api/v1/admin/admins`, {
    method: 'POST', body: { fullName: 'Benchmark Test', email: 'benchmark@test.jo', password: 'test1234', adminRole: 'support' }
  }, 201);
  
  if (createRes.ok) {
    const adminId = createRes.data.admin.id;
    await test('Delete admin', `${API}/api/v1/admin/admins/${adminId}`, { method: 'DELETE' });
  }

  // Results
  const totalTime = Date.now() - startTime;
  console.log('\n═══════════════════════════════════════');
  console.log(`📊 RESULTS (${(totalTime/1000).toFixed(1)}s)`);
  console.log(`   Total: ${totalTests}  ✅ ${passed}  ❌ ${failed}  (${((passed/totalTests)*100).toFixed(1)}%)`);
  
  if (errors.length > 0) {
    console.log(`\n❌ FAILURES (${errors.length}):`);
    errors.forEach(e => console.log(`   - ${e.name}: ${e.error || `status ${e.got}`}`));
  }

  console.log();
  process.exit(failed > 0 ? 1 : 0);
})();
