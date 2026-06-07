#!/bin/bash
# ===================================================
# N8N Self-Hosted — установка на Ubuntu (Oracle Cloud Free Tier)
# Запуск: chmod +x n8n-oracle-setup.sh && sudo ./n8n-oracle-setup.sh
# ===================================================
set -e

echo "=== N8N Setup for Oracle Cloud ==="

# --- 1. Обновление системы ---
echo "[1/6] Updating system..."
apt update && apt upgrade -y

# --- 2. Docker ---
echo "[2/6] Installing Docker..."
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker --now
else
    echo "Docker already installed."
fi

# --- 3. N8N — сохраняем данные в отдельный volume ---
echo "[3/6] Starting N8N container..."
docker rm -f n8n 2>/dev/null || true
docker run -d \
    --name n8n \
    --restart unless-stopped \
    -p 5678:5678 \
    -e N8N_HOST="REPLACE_WITH_YOUR_DOMAIN_OR_IP" \
    -e N8N_PROTOCOL="https" \
    -e WEBHOOK_URL="https://REPLACE_WITH_YOUR_DOMAIN_OR_IP" \
    -v n8n_data:/home/node/.n8n \
    n8nio/n8n

# --- 4. Firewall — открыть порт 5678 только для своего IP в начале ---
echo "[4/6] Configuring firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 5678/tcp
ufw --force enable
ufw status verbose

# --- 5. Cloudflare Tunnel (опционально — раскомментируй, если нужен домен) ---
# echo "[5/6] Installing Cloudflare tunnel..."
# curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared
# chmod +x /usr/local/bin/cloudflared
# echo "Run: cloudflared tunnel login — откроет браузер для авторизации в Cloudflare"

# --- 6. Финал ---
PUBLIC_IP=$(curl -s ifconfig.me)
echo ""
echo "=== Setup Complete ==="
echo "N8N running at: http://${PUBLIC_IP}:5678"
echo ""
echo "Next steps:"
echo "1. Open http://${PUBLIC_IP}:5678 in browser"
echo "2. Create admin account"
echo "3. SSH: ssh -i oracle-key.pem ubuntu@${PUBLIC_IP}"
echo ""
echo "Security reminder: enable SSL before production use."
