const { execSync } = require('child_process');
try {
  console.log("Removing old env var...");
  execSync('vercel env rm NEXT_PUBLIC_API_URL production -y');
} catch(e) {}
console.log("Adding new env var...");
execSync('vercel env add NEXT_PUBLIC_API_URL production', { input: 'https://evo-backend.vercel.app' });
console.log("Done.");
