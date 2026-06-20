#!/usr/bin/env node
/**
 * Test CRUD operations for Captains and Coupons
 * Run: node test-crud.js
 */

const http = require('http');

const BASE_URL = 'http://localhost:5000';

// Admin credentials from .env.local
const ADMIN_EMAIL = 'admin@evo.jo';
const ADMIN_PASSWORD = '123456';

let adminToken = null;

// ─────────────────────────────────────────────────────
// HELPER: Make HTTP requests
// ─────────────────────────────────────────────────────

function makeRequest(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(BASE_URL + path);
    
    const options = {
      method,
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, body: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });

    req.on('error', reject);
    
    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

// ─────────────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────────────

async function runTests() {
  console.log('\n🚀 Starting EVO CRUD Tests...\n');

  try {
    // 1. LOGIN
    console.log('📝 [1] Logging in as admin...');
    const loginRes = await makeRequest('POST', '/api/v1/admin/login', {
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
    });
    console.log(`   Status: ${loginRes.status}`);
    if (loginRes.status !== 200) {
      console.error('   ❌ Login failed:', loginRes.body);
      process.exit(1);
    }
    adminToken = loginRes.body.accessToken;
    console.log(`   ✅ Token acquired: ${adminToken.substring(0, 30)}...`);

    // 2. CREATE DRIVER
    console.log('\n🧑‍💼 [2] Creating new captain (driver)...');
    const timestamp = Date.now();
    const driverRes = await makeRequest('POST', '/api/v1/admin/drivers', {
      fullName: 'محمود التكاسي',
      phone: `+962${Math.floor(Math.random() * 9000000) + 1000000}`,
      email: `mahmoud.driver.${timestamp}@evo.jo`,
      carType: 'ev_taxi',
      carModel: 'Tesla Model 3',
      carPlate: `ACC-${5000 + Math.floor(Math.random() * 9000)}`,
      cliqAlias: 'mahmoud_cliq',
    }, adminToken);
    console.log(`   Status: ${driverRes.status}`);
    if (driverRes.status !== 201) {
      console.error('   ❌ Driver creation failed:', driverRes.body);
    } else {
      const driverId = driverRes.body.driver.id;
      console.log(`   ✅ Captain created successfully!`);
      console.log(`      ID: ${driverId}`);
      console.log(`      Name: ${driverRes.body.driver.fullName}`);
      console.log(`      Plate: ${driverRes.body.driver.carPlate}`);
      console.log(`      Car Type: ${driverRes.body.driver.carType}`);
      console.log(`      Wallet: ${driverRes.body.driver.walletBalance} JOD`);

      // 3. DELETE DRIVER
      console.log(`\n🗑️  [3] Removing captain (driver ID: ${driverId.substring(0, 8)}...)...`);
      const deleteRes = await makeRequest('DELETE', `/api/v1/admin/drivers/${driverId}`, null, adminToken);
      console.log(`   Status: ${deleteRes.status}`);
      if (deleteRes.status !== 200) {
        console.error('   ❌ Driver deletion failed:', deleteRes.body);
      } else {
        console.log(`   ✅ Captain removed successfully!`);
        console.log(`      ${deleteRes.body.message}`);
      }
    }

    // 4. CREATE COUPON
    console.log('\n🎟️  [4] Creating new coupon...');
    const couponRes = await makeRequest('POST', '/api/v1/admin/promo-codes', {
      code: 'SUMMER2026',
      discountType: 'percentage',
      discountValue: 15,
      maxDiscountJod: 5,
      minFareJod: 3,
      maxTotalUses: 100,
      maxPerUser: 2,
      applicableCarTypes: ['ev_taxi', 'ev_sedan'],
      validFrom: new Date().toISOString().split('T')[0],
      validUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    }, adminToken);
    console.log(`   Status: ${couponRes.status}`);
    if (couponRes.status !== 201) {
      console.error('   ❌ Coupon creation failed:', couponRes.body);
    } else {
      const couponId = couponRes.body.promoCode.id;
      console.log(`   ✅ Coupon created successfully!`);
      console.log(`      ID: ${couponId}`);
      console.log(`      Code: ${couponRes.body.promoCode.code}`);
      console.log(`      Discount: ${couponRes.body.promoCode.discount_value}% (Max: ${couponRes.body.promoCode.max_discount_jod} JOD)`);
      console.log(`      Valid Until: ${couponRes.body.promoCode.valid_until}`);

      // 5. DELETE COUPON
      console.log(`\n🗑️  [5] Removing coupon (ID: ${couponId.substring(0, 8)}...)...`);
      const deleteCouponRes = await makeRequest('DELETE', `/api/v1/admin/promo-codes/${couponId}`, null, adminToken);
      console.log(`   Status: ${deleteCouponRes.status}`);
      if (deleteCouponRes.status !== 200) {
        console.error('   ❌ Coupon deletion failed:', deleteCouponRes.body);
      } else {
        console.log(`   ✅ Coupon removed successfully!`);
      }
    }

    // 6. GET DRIVERS LIST
    console.log('\n📋 [6] Listing all drivers...');
    const driversRes = await makeRequest('GET', '/api/v1/admin/drivers', null, adminToken);
    console.log(`   Status: ${driversRes.status}`);
    if (driversRes.status !== 200) {
      console.error('   ❌ Failed to fetch drivers:', driversRes.body);
    } else {
      console.log(`   ✅ Total drivers: ${driversRes.body.total}`);
      if (driversRes.body.drivers && driversRes.body.drivers.length > 0) {
        console.log(`   First driver: ${driversRes.body.drivers[0].full_name} (${driversRes.body.drivers[0].car_plate})`);
      }
    }

    // 7. GET COUPONS LIST
    console.log('\n📋 [7] Listing all coupons...');
    const couponsRes = await makeRequest('GET', '/api/v1/admin/promo-codes', null, adminToken);
    console.log(`   Status: ${couponsRes.status}`);
    if (couponsRes.status !== 200) {
      console.error('   ❌ Failed to fetch coupons:', couponsRes.body);
    } else {
      console.log(`   ✅ Total coupons: ${couponsRes.body.promoCodes?.length || 0}`);
      if (couponsRes.body.promoCodes && couponsRes.body.promoCodes.length > 0) {
        console.log(`   First coupon: ${couponsRes.body.promoCodes[0].code}`);
      }
    }

    console.log('\n✅ All tests completed!\n');
  } catch (error) {
    console.error('\n❌ Test error:', error.message);
    process.exit(1);
  }
}

runTests();
