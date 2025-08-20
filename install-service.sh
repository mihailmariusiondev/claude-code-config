#!/bin/bash

# Script para instalar el servicio systemd de Claude Code Sync

echo "=== Instalando Servicio Claude Code Sync ==="

# Verificar que el archivo de servicio existe
if [ ! -f "/tmp/claude-sync.service" ]; then
    echo "❌ Error: /tmp/claude-sync.service no existe"
    exit 1
fi

# 1. Instalar el servicio
echo "1. Instalando archivo de servicio..."
sudo cp /tmp/claude-sync.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/claude-sync.service

# 2. Recargar systemd y habilitar el servicio
echo "2. Recargando systemd..."
sudo systemctl daemon-reload

echo "3. Habilitando servicio para auto-start..."
sudo systemctl enable claude-sync.service

# 3. Detener proceso manual actual
echo "4. Deteniendo proceso manual actual..."
pkill -f "sync.sh" || echo "No hay procesos sync.sh ejecutándose"

# 4. Iniciar el servicio
echo "5. Iniciando servicio systemd..."
sudo systemctl start claude-sync.service

# 5. Verificar estado
echo "6. Verificando estado del servicio..."
sudo systemctl status claude-sync.service

echo ""
echo "✅ Instalación completada!"
echo ""
echo "Comandos útiles:"
echo "  Ver logs:     sudo journalctl -u claude-sync.service -f"
echo "  Reiniciar:    sudo systemctl restart claude-sync.service"
echo "  Parar:        sudo systemctl stop claude-sync.service"
echo "  Estado:       sudo systemctl status claude-sync.service"