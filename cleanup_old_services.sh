#!/bin/bash
# Script para limpiar servicios antiguos de Claude Sync

echo "🧹 Limpiando servicios Claude Sync antiguos..."

# 1. Matar procesos Python daemon
echo "1️⃣ Matando procesos Python daemon..."
pkill -f "install.py --daemon" && echo "✅ Procesos Python eliminados" || echo "ℹ️ No había procesos Python"

# 2. Parar y deshabilitar servicio systemd (requiere sudo)
echo "2️⃣ Parando servicio systemd..."
if ls /etc/systemd/system/claude-sync* >/dev/null 2>&1; then
    echo "⚠️ Servicio systemd encontrado. Ejecuta manualmente:"
    echo "   sudo systemctl stop claude-sync.service"
    echo "   sudo systemctl disable claude-sync.service"
    echo "   sudo rm /etc/systemd/system/claude-sync.service"
    echo "   sudo systemctl daemon-reload"
else
    echo "ℹ️ No hay servicios systemd"
fi

# 3. Limpiar cron jobs antiguos relacionados con install.py
echo "3️⃣ Limpiando cron jobs antiguos..."
if crontab -l 2>/dev/null | grep -q "install.py"; then
    echo "⚠️ Cron jobs con install.py encontrados:"
    crontab -l | grep "install.py" || true
    echo "   Ejecuta: crontab -e  (y borra las líneas con install.py)"
else
    echo "✅ No hay cron jobs antiguos"
fi

# 4. Verificar estado final
echo "4️⃣ Verificación final..."
if ps aux | grep -q "install.py --daemon"; then
    echo "❌ Aún hay procesos corriendo"
else
    echo "✅ No hay procesos Python corriendo"
fi

echo ""
echo "🎯 SIGUIENTE PASO: Ejecutar ./setup_sync.sh para configurar el sistema simple"