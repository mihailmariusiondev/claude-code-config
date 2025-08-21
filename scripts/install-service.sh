#!/bin/bash

# Claude Code Config - Service Installer
# Instala o reinstala el servicio systemd

echo "🔧 Instalando servicio claude-sync..."

# Auto-detectar rutas dinámicas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CURRENT_USER="$(whoami)"
SERVICE_FILE="/etc/systemd/system/claude-sync.service"

echo "📁 Usando directorio: $REPO_DIR"
echo "👤 Usuario actual: $CURRENT_USER"

# Parar servicio si existe
sudo systemctl stop claude-sync.service 2>/dev/null || true

# Crear archivo de servicio con rutas dinámicas
sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=Claude Code Config Auto-Sync Service
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_USER
WorkingDirectory=$REPO_DIR
ExecStart=$REPO_DIR/scripts/sync.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd, habilitar e iniciar servicio
sudo systemctl daemon-reload
sudo systemctl enable claude-sync.service
sudo systemctl start claude-sync.service

echo "✅ Servicio instalado y iniciado"
echo ""
echo "📊 Estado del servicio:"
sudo systemctl status claude-sync.service --no-pager -l