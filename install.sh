#!/bin/bash
set -euo pipefail

# Claude Code Config - SCRIPT ÚNICO TOTAL
# Restaura + Instala servicio + Sync automático
# Version 3.3 - Un solo archivo, cero folders extras

echo "🚀 Claude Code Config - Script Único v3.3"
echo "📦 Restaura + Servicio + Sync cada 1 minuto"
echo ""

#=============================================================================
# VARIABLES GLOBALES
#=============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
# Detectar directorio home del usuario real
if [[ -n "${SUDO_USER:-}" ]]; then
    USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
    USER_HOME="$HOME"
fi
CLAUDE_DIR="$USER_HOME/.claude"
CONFIG_DIR="$REPO_DIR/claude_config"
SERVICE_FILE="/etc/systemd/system/claude-sync.service"
# Detectar usuario real (cuando se ejecuta con sudo)
if [[ -n "${SUDO_USER:-}" ]]; then
    CURRENT_USER="$SUDO_USER"
else
    CURRENT_USER="$(whoami)"
fi

#=============================================================================
# VALIDACIONES BÁSICAS
#=============================================================================
# Permitir sudo para operaciones systemd, pero alertar si es root directo
if [[ $EUID -eq 0 ]] && [[ -z "${SUDO_USER:-}" ]]; then
    echo "❌ No ejecutar como root directo. Usa: sudo ./install.sh"
    exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
    echo "❌ systemctl no encontrado. Se requiere systemd."
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo "❌ git no encontrado. Se requiere git."
    exit 1
fi

#=============================================================================
# PASO 1: RESTAURAR CONFIGURACIÓN
#=============================================================================
echo "📁 PASO 1/3: Restaurando configuración ~/.claude/"
echo "Fuente: $CONFIG_DIR"
echo "Destino: $CLAUDE_DIR"

# Crear directorio
mkdir -p "$CLAUDE_DIR" "$CONFIG_DIR" "$REPO_DIR/logs"

# Función simple para copiar archivos
copy_file() {
    local src="$1"
    local dst="$2" 
    local name="$3"
    
    if [ -f "$src" ]; then
        echo "📄 Copiando $name..."
        cp "$src" "$dst"
        echo "✅ $name copiado"
    else
        echo "⚠️ $name no encontrado"
    fi
}

# Copiar archivos principales
copy_file "$CONFIG_DIR/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"
copy_file "$CONFIG_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md"
copy_file "$CONFIG_DIR/CLAUDE_CODE_REFERENCE.md" "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md" "CLAUDE_CODE_REFERENCE.md"

# Copiar directorios
if [ -d "$CONFIG_DIR/commands" ]; then
    echo "📁 Copiando commands/"
    cp -r "$CONFIG_DIR/commands" "$CLAUDE_DIR/"
    echo "✅ commands/ copiado"
fi

if [ -d "$CONFIG_DIR/agents" ]; then
    echo "📁 Copiando agents/"
    cp -r "$CONFIG_DIR/agents" "$CLAUDE_DIR/"
    echo "✅ agents/ copiado"
fi

# Procesar .claude.json
if [ -f "$CONFIG_DIR/.claude.json" ]; then
    echo "📋 Procesando .claude.json..."
    
    if python3 -c "import json; json.load(open('$CONFIG_DIR/.claude.json'))" 2>/dev/null; then
        if [ -f "$USER_HOME/.claude.json" ]; then
            # Backup único
            if [ ! -f "$USER_HOME/.claude.json.backup" ]; then
                cp "$USER_HOME/.claude.json" "$USER_HOME/.claude.json.backup"
                echo "✅ Backup creado"
            fi
            
            # Merge mcpServers
            python3 -c "
import json
try:
    with open('$CONFIG_DIR/.claude.json', 'r') as f:
        config_data = json.load(f)
    
    with open('$USER_HOME/.claude.json', 'r') as f:
        user_data = json.load(f)
    
    if 'mcpServers' in config_data:
        user_data['mcpServers'] = config_data['mcpServers']
        
        with open('$USER_HOME/.claude.json', 'w') as f:
            json.dump(user_data, f, indent=2)
        print('✅ MCP servers fusionados')
    else:
        print('⚠️ No hay mcpServers')
except Exception as e:
    print(f'❌ Error: {e}')
    exit(1)
"
        else
            # Copiar completo
            cp "$CONFIG_DIR/.claude.json" "$USER_HOME/.claude.json"
            chmod 600 "$USER_HOME/.claude.json"
            echo "✅ .claude.json copiado"
        fi
    else
        echo "❌ .claude.json inválido"
    fi
fi

echo "✅ PASO 1 COMPLETADO: Configuración restaurada"
echo ""

#=============================================================================
# PASO 2: INSTALAR SERVICIO SYSTEMD
#=============================================================================
echo "⚙️ PASO 2/3: Instalando servicio claude-sync.service"

# Detener servicio si existe
if systemctl is-active --quiet claude-sync.service 2>/dev/null; then
    echo "🛑 Deteniendo servicio actual..."
    sudo systemctl stop claude-sync.service
fi

# Crear archivo de servicio
echo "📝 Creando archivo systemd..."
sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=Claude Code Config Auto-Sync Service  
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_USER
WorkingDirectory=$REPO_DIR
ExecStart=$REPO_DIR/install.sh --daemon
Restart=always
RestartSec=10
TimeoutStopSec=30

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=claude-sync

# Security
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=$REPO_DIR $USER_HOME/.claude $USER_HOME/.claude.json
ProtectHome=read-only

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd
echo "🔄 Recargando systemd..."
sudo systemctl daemon-reload

# Habilitar e iniciar
echo "🚀 Habilitando e iniciando servicio..."
sudo systemctl enable claude-sync.service
sudo systemctl start claude-sync.service

# Verificar
sleep 2
if systemctl is-active --quiet claude-sync.service; then
    echo "✅ PASO 2 COMPLETADO: Servicio activo"
else
    echo "❌ Error: Servicio no se pudo iniciar"
    exit 1
fi

echo ""

#=============================================================================
# PASO 3: MODO DAEMON (SYNC AUTOMÁTICO)
#=============================================================================
if [[ "${1:-}" == "--daemon" ]]; then
    echo "🔄 MODO DAEMON: Iniciando sync automático cada 1 minuto..."
    
    # Función de logging simple
    log() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$REPO_DIR/logs/sync.log"
    }
    
    # Loop infinito de sync
    while true; do
        log "🔍 Checking for changes..."
        
        # Copiar archivos ~/.claude/ → claude_config/
        [ -f "$CLAUDE_DIR/settings.json" ] && cp "$CLAUDE_DIR/settings.json" "$CONFIG_DIR/settings.json" 2>/dev/null
        [ -f "$CLAUDE_DIR/CLAUDE.md" ] && cp "$CLAUDE_DIR/CLAUDE.md" "$CONFIG_DIR/CLAUDE.md" 2>/dev/null  
        [ -f "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md" ] && cp "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md" "$CONFIG_DIR/CLAUDE_CODE_REFERENCE.md" 2>/dev/null
        [ -f "$USER_HOME/.claude.json" ] && cp "$USER_HOME/.claude.json" "$CONFIG_DIR/.claude.json" 2>/dev/null
        [ -d "$CLAUDE_DIR/commands" ] && cp -r "$CLAUDE_DIR/commands" "$CONFIG_DIR/" 2>/dev/null
        [ -d "$CLAUDE_DIR/agents" ] && cp -r "$CLAUDE_DIR/agents" "$CONFIG_DIR/" 2>/dev/null
        
        # Git commit si hay cambios
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            log "📝 Local changes detected, committing..."
            git add . 2>/dev/null
            if git commit -m "auto-sync $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null; then
                log "✅ Changes committed"
                
                # Force push (siempre)
                log "🚀 Force pushing to GitHub..."
                if git push --force origin main 2>/dev/null; then
                    log "✅ Force push successful"
                else
                    log "❌ Force push failed"
                fi
            fi
        else
            log "💤 No changes detected"
        fi
        
        # Wait 1 minuto
        log "⏱️ Waiting 1 minute until next sync..."
        sleep 60
    done
fi

#=============================================================================
# RESUMEN FINAL (MODO INSTALACIÓN)
#=============================================================================
echo "🎉 INSTALACIÓN COMPLETADA!"
echo ""
echo "📊 Estado del sistema:"
echo "• Configuración: ~/.claude/ restaurada ✅"
echo "• Servicio: claude-sync.service activo ✅" 
echo "• Frecuencia: Sync cada 1 minuto ✅"
echo "• Método: Force push (sin conflictos) ✅"
echo ""
echo "📋 Comandos útiles:"
echo "• Estado: sudo systemctl status claude-sync.service"
echo "• Logs: sudo journalctl -u claude-sync.service -f"
echo "• Logs detallados: tail -f logs/sync.log"
echo "• Actualizar: ./install.sh"
echo "• Parar: sudo systemctl stop claude-sync.service"
echo ""
echo "🔥 UN SOLO SCRIPT PARA TODO - Ready to rock!"