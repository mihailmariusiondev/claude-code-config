#!/bin/bash
# Claude Sync - Versión Simple y Efectiva
# Solo hace lo que necesitas: rsync ~/.claude/ a VPS

# Auto-detectar máquina
MACHINE=$(hostname)-$(whoami)
VPS="claude-user@188.245.53.238"
DEST_PATH="claude-configs/$MACHINE"

echo "🔄 Sincronizando $MACHINE a VPS..."

# rsync simple y efectivo
rsync -avz --delete \
    -e "ssh -i ~/.ssh/claude_key -o StrictHostKeyChecking=no" \
    ~/.claude/ ~/.claude.json \
    $VPS:~/$DEST_PATH/

if [ $? -eq 0 ]; then
    echo "✅ Sync completado: $MACHINE → $VPS:~/$DEST_PATH/"
else
    echo "❌ Error en sync"
fi