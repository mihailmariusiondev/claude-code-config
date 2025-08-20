#!/bin/bash

echo "=== Test del Sistema de Sincronización Claude Code ==="
echo ""

echo "1. Verificando servicio systemd..."
sudo systemctl status claude-sync.service --no-pager | head -10

echo ""
echo "2. Reiniciando servicio para aplicar correcciones..."
sudo systemctl restart claude-sync.service

echo ""
echo "3. Esperando 10 segundos para que se ejecute..."
sleep 10

echo ""
echo "4. Verificando estado después de reinicio..."
sudo systemctl status claude-sync.service --no-pager | head -8

echo ""
echo "5. Verificando últimos logs..."
echo "--- Logs del servicio ---"
sudo journalctl -u claude-sync.service --since "30 seconds ago" --no-pager | tail -5

echo ""
echo "--- Logs del script ---"
tail -5 /home/mihai-usl/repos/personal/claude-code-config/logs/sync.log

echo ""
echo "6. Verificando archivos sincronizados..."
ls -la /home/mihai-usl/repos/personal/claude-code-config/ | grep -E "\.(json|md|sh)$"

echo ""
echo "7. Verificando MCPs extraídos..."
echo "Tamaño mcpServers.json: $(wc -c < /home/mihai-usl/repos/personal/claude-code-config/mcpServers.json) bytes"
echo "Contenido:"
cat /home/mihai-usl/repos/personal/claude-code-config/mcpServers.json

echo ""
echo "=== Test Completado ==="