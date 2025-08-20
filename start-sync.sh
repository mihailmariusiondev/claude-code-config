#!/bin/bash

# Claude Code Config Auto-Start Script
# Mantiene sync.sh siempre ejecutándose

REPO_DIR="/home/mihai-usl/repos/personal/claude-code-config"
SCRIPT_NAME="sync.sh"
LOG_FILE="$REPO_DIR/logs/startup.log"

# Crear directorio logs si no existe
mkdir -p "$REPO_DIR/logs"

# Función para logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - STARTUP: $1" | tee -a "$LOG_FILE"
}

# Cambiar al directorio del repo
cd "$REPO_DIR" || {
    log "ERROR: No se puede acceder a $REPO_DIR"
    exit 1
}

log "=== Claude Sync Auto-Starter Iniciado ==="

while true; do
    # Verificar si sync.sh está ejecutándose
    if ! pgrep -f "$SCRIPT_NAME" > /dev/null; then
        log "⚠ sync.sh no está ejecutándose, iniciando..."
        
        # Ejecutar sync.sh en background
        if nohup ./"$SCRIPT_NAME" > /dev/null 2>&1 & then
            sleep 2
            PID=$(pgrep -f "$SCRIPT_NAME")
            if [ -n "$PID" ]; then
                log "✅ sync.sh iniciado exitosamente (PID: $PID)"
            else
                log "❌ Error al iniciar sync.sh"
            fi
        else
            log "❌ Error ejecutando sync.sh"
        fi
    else
        PID=$(pgrep -f "$SCRIPT_NAME")
        log "✅ sync.sh está ejecutándose correctamente (PID: $PID)"
    fi
    
    # Verificar cada 30 segundos
    sleep 30
done