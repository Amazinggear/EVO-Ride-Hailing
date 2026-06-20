#!/usr/bin/env node
// ══════════════════════════════════════════════════════
// EVO Firebase Setup Helper
// Watches Downloads folder and auto-places Firebase files
// Usage: node firebase-setup.js
// ══════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');

const DOWNLOADS = path.join(process.env.USERPROFILE || process.env.HOME, 'Downloads');
const BACKEND_DIR = path.join(__dirname, 'evo-backend');
const PASSENGER_ANDROID = path.join(__dirname, 'evo_passenger', 'android', 'app');
const DRIVER_ANDROID = path.join(__dirname, 'evo_driver', 'android', 'app');

console.log('═══════════════════════════════════════════════════');
console.log('  EVO Firebase Setup Helper');
console.log('═══════════════════════════════════════════════════');
console.log('');

function checkAndCopyFiles() {
  const files = fs.readdirSync(DOWNLOADS);
  let found = false;

  // Check for service account JSON (firebase-adminsdk files)
  const serviceAccountFile = files.find(f => 
    f.includes('firebase-adminsdk') || f.includes('service-account') || f.includes('serviceAccount')
  );
  
  if (serviceAccountFile) {
    const src = path.join(DOWNLOADS, serviceAccountFile);
    const dst = path.join(BACKEND_DIR, 'firebase-service-account.json');
    fs.copyFileSync(src, dst);
    console.log(`✅ Service Account Key copied → evo-backend/firebase-service-account.json`);
    console.log(`   (from: ${serviceAccountFile})`);
    found = true;
  }

  // Check for google-services.json files
  const googleServicesFiles = files.filter(f => f === 'google-services.json');
  
  if (googleServicesFiles.length > 0) {
    const src = path.join(DOWNLOADS, 'google-services.json');
    
    // Read the file to determine which app it's for
    try {
      const content = JSON.parse(fs.readFileSync(src, 'utf8'));
      const clients = content.client || [];
      
      for (const client of clients) {
        const packageName = client?.client_info?.android_client_info?.package_name;
        
        if (packageName === 'com.evo.passenger') {
          const dst = path.join(PASSENGER_ANDROID, 'google-services.json');
          fs.copyFileSync(src, dst);
          console.log(`✅ google-services.json for PASSENGER copied → evo_passenger/android/app/`);
          found = true;
        } else if (packageName === 'com.evo.driver') {
          const dst = path.join(DRIVER_ANDROID, 'google-services.json');
          fs.copyFileSync(src, dst);
          console.log(`✅ google-services.json for DRIVER copied → evo_driver/android/app/`);
          found = true;
        } else {
          console.log(`⚠️  Found google-services.json but package name is: ${packageName}`);
          console.log(`    Expected: com.evo.passenger or com.evo.driver`);
        }
      }
    } catch (e) {
      console.log(`⚠️  Could not parse google-services.json: ${e.message}`);
    }
  }

  if (!found) {
    console.log('⏳ No Firebase files found in Downloads yet...');
    console.log(`   Watching: ${DOWNLOADS}`);
    console.log('');
    console.log('   Looking for:');
    console.log('   1. evo-carshare-firebase-adminsdk-*.json  (Service Account)');
    console.log('   2. google-services.json                   (Android app config)');
  }

  return found;
}

// Run once immediately
console.log(`📁 Scanning Downloads folder...`);
const found = checkAndCopyFiles();

if (!found) {
  console.log('');
  console.log('═══════════════════════════════════════════════════');
  console.log('  INSTRUCTIONS: Do these steps in Firebase:');
  console.log('');
  console.log('  1. Service Account Key:');
  console.log('     https://console.firebase.google.com/project/evo-carshare/settings/serviceaccounts/adminsdk');
  console.log('     → Click "Generate new private key" → "Generate key"');
  console.log('     → File downloads to your Downloads folder');
  console.log('     → Run this script again!');
  console.log('');
  console.log('  2. Passenger App:');
  console.log('     https://console.firebase.google.com/project/evo-carshare/overview');
  console.log('     → Add app → Android → com.evo.passenger');
  console.log('     → Download google-services.json');
  console.log('     → Run this script again!');
  console.log('');
  console.log('  3. Driver App:');
  console.log('     → Add app → Android → com.evo.driver');
  console.log('     → Download google-services.json');  
  console.log('     → Run this script again!');
  console.log('═══════════════════════════════════════════════════');
} else {
  console.log('');
  console.log('✅ Done! Files placed correctly.');
  console.log('   Now restart the backend: cd evo-backend && npm start');
}
