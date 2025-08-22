#!/bin/bash
# Setup automático - instala SSH key y configura cron
# Ejecutar UNA VEZ en cada máquina nueva

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_DIR="$HOME/.ssh"

echo "🚀 Claude Sync - Setup automático"
echo "📱 Máquina: $(hostname)-$(whoami)"

# 1. Crear directorio SSH si no existe
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# 2. Copiar SSH key
cp "$SCRIPT_DIR/claude_key" "$SSH_DIR/claude_key"
chmod 600 "$SSH_DIR/claude_key"
echo "✅ SSH key instalada: $SSH_DIR/claude_key"

# 3. Probar sync manual
echo "🔍 Probando sync manual..."
"$SCRIPT_DIR/sync_claude.sh"

# 4. Configurar cron automático
CRON_JOB="*/1 * * * * $SCRIPT_DIR/sync_claude.sh >> $HOME/.claude_sync.log 2>&1"

# Verificar si ya existe en cron
if crontab -l 2>/dev/null | grep -q "sync_claude.sh"; then
    echo "✅ Cron job ya existe"
else
    # Añadir a cron
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✅ Cron job configurado - sync cada minuto"
fi

echo ""
echo "🎉 ¡SETUP COMPLETADO!"
echo "✅ Sync automático cada minuto"
echo "📋 Ver logs: tail -f ~/.claude_sync.log"
echo "🔧 Sync manual: $SCRIPT_DIR/sync_claude.sh"