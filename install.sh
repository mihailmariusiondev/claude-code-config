#!/bin/bash
set -euo pipefail

# Claude Code Config - Unified Installer
# Restaura configuración + instala/actualiza servicio systemd

echo "🚀 Claude Code Config - Instalador Unificado v3.2"
echo ""

# Auto-detectar rutas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESTORE_SCRIPT="$SCRIPT_DIR/scripts/restore.sh"
SERVICE_SCRIPT="$SCRIPT_DIR/scripts/install-service.sh"

# Validaciones básicas
if [[ $EUID -eq 0 ]]; then
    echo "❌ No ejecutar como root"
    exit 1
fi

if [ ! -f "$RESTORE_SCRIPT" ] || [ ! -f "$SERVICE_SCRIPT" ]; then
    echo "❌ Scripts no encontrados en: $SCRIPT_DIR/scripts/"
    exit 1
fi

# Paso 1: Restaurar configuración
echo "📁 Paso 1/2: Restaurando configuración Claude Code..."
if "$RESTORE_SCRIPT"; then
    echo "✅ Configuración restaurada"
else
    echo "❌ Error restaurando configuración"
    exit 1
fi

echo ""

# Paso 2: Instalar/actualizar servicio
echo "⚙️ Paso 2/2: Instalando/actualizando servicio automático..."
if "$SERVICE_SCRIPT"; then
    echo "✅ Servicio configurado"
else
    echo "❌ Error configurando servicio"
    exit 1
fi

echo ""
echo "🎉 Instalación completada!"
echo ""
echo "📊 Estado del sistema:"
echo "• Configuración: ~/.claude/ restaurada"
echo "• Servicio: claude-sync.service activo"
echo "• Frecuencia: Sync cada 1 minuto"
echo "• Método: Force push (sin conflictos)"
echo ""
echo "📋 Comandos útiles:"
echo "• Estado: sudo systemctl status claude-sync.service"
echo "• Logs: sudo journalctl -u claude-sync.service -f"
echo "• Actualizar: ./install.sh (este script)"
echo ""