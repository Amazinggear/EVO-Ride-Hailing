#!/bin/bash
# ================================================
# EVO Backend — Oracle Cloud / Ubuntu 22.04 Setup
# Run as root or with sudo
# ================================================

set -e
echo "🚀 Starting EVO Backend Server Setup..."

# ── 1. Update & install essentials ──
apt update && apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs git nginx ufw
npm install -g pm2

# ── 2. Firewall ──
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# ── 3. Clone the project ──
cd /opt
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git evo-backend || true
cd evo-backend/evo-backend

# ── 4. Create .env ──
cat > .env << 'ENVEOF'
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://user:pass@host:5432/evo_db?sslmode=require
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-secret
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-client-email
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_KEY\n-----END PRIVATE KEY-----"
ONESIGNAL_APP_ID=your-onesignal-app-id
ONESIGNAL_REST_API_KEY=your-onesignal-rest-key
REDIS_URL=redis://your-redis-url:6379
ALLOWED_ORIGINS=https://evo-admin.vercel.app,http://localhost:3000
ENVEOF

echo "⚠️ Edit /opt/evo-backend/evo-backend/.env with real values!"

# ── 5. Install dependencies ──
npm install --production

# ── 6. Start with PM2 (auto-restart, 24/7) ──
pm2 start server.js --name evo-backend --time
pm2 save
pm2 startup systemd

# ── 7. Configure Nginx reverse proxy ──
cat > /etc/nginx/sites-available/evo-backend << 'NGXEOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400s;
    }
}
NGXEOF

ln -sf /etc/nginx/sites-available/evo-backend /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# ── 8. Setup automatic restart with crontab ──
(crontab -l 2>/dev/null; echo "@reboot pm2 resurrect") | crontab -

echo "✅ EVO Backend is LIVE!"
echo "📍 Server IP: $(curl -s ifconfig.me)"
echo "🔗 Health: http://$(curl -s ifconfig.me)/health"
echo ""
echo "📝 NEXT STEP: Set NEXT_PUBLIC_API_URL on Vercel to:"
echo "   http://$(curl -s ifconfig.me)"
