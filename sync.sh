#!/bin/bash

# Claude Code Config Auto-Sync Script
# Sincroniza configuración cada minuto

REPO_DIR="/home/mihai-usl/repos/personal/claude-code-config"
CLAUDE_DIR="$HOME/.claude"
LOG_FILE="$REPO_DIR/logs/sync.log"
ERROR_LOG="$REPO_DIR/logs/error.log"

# Crear directorio logs si no existe
mkdir -p "$REPO_DIR/logs"

cd "$REPO_DIR"

# Función para logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" | tee -a "$ERROR_LOG" >&2
}

log "=== Claude Code Config Auto-Sync Started ==="

while true; do
    log "Checking for changes..."
    
    # Copiar archivos principales de configuración
    if [ -f "$CLAUDE_DIR/settings.json" ]; then
        cp "$CLAUDE_DIR/settings.json" ./ 2>/dev/null && log "✓ Copied settings.json" || error_log "Failed to copy settings.json"
    fi
    
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        cp "$CLAUDE_DIR/CLAUDE.md" ./ 2>/dev/null && log "✓ Copied CLAUDE.md" || error_log "Failed to copy CLAUDE.md"
    fi
    
    if [ -f "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md" ]; then
        cp "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md" ./ 2>/dev/null && log "✓ Copied CLAUDE_CODE_REFERENCE.md" || error_log "Failed to copy CLAUDE_CODE_REFERENCE.md"
    fi
    
    if [ -f "$CLAUDE_DIR/fetch-claude-docs.sh" ]; then
        cp "$CLAUDE_DIR/fetch-claude-docs.sh" ./ 2>/dev/null && chmod +x fetch-claude-docs.sh && log "✓ Copied fetch-claude-docs.sh" || error_log "Failed to copy fetch-claude-docs.sh"
    fi
    
    # Extraer solo sección mcpServers de ~/.claude.json
    if [ -f "$HOME/.claude.json" ]; then
        if jq '.mcpServers // {}' "$HOME/.claude.json" > mcpServers.json 2>/dev/null; then
            log "✓ Extracted mcpServers.json"
        else
            echo "{}" > mcpServers.json
            error_log "Failed to extract mcpServers, created empty file"
        fi
    else
        echo "{}" > mcpServers.json
        log "⚠ ~/.claude.json not found, created empty mcpServers.json"
    fi
    
    # Copiar directorios commands/ y agents/ si existen
    if [ -d "$CLAUDE_DIR/commands" ]; then
        cp -r "$CLAUDE_DIR/commands" ./ 2>/dev/null && log "✓ Copied commands directory" || error_log "Failed to copy commands directory"
    fi
    
    if [ -d "$CLAUDE_DIR/agents" ]; then
        cp -r "$CLAUDE_DIR/agents" ./ 2>/dev/null && log "✓ Copied agents directory" || error_log "Failed to copy agents directory"
    fi
    
    # Verificar si hay cambios y hacer sync
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        if git add . 2>/dev/null; then
            if git commit -m "auto-sync $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null; then
                if git push origin main 2>/dev/null; then
                    log "🚀 Changes synced successfully to GitHub"
                else
                    error_log "Failed to push to GitHub"
                fi
            else
                error_log "Failed to commit changes"
            fi
        else
            error_log "Failed to add files to git"
        fi
    else
        log "💤 No changes detected"
    fi
    
    # Esperar 5 minutos
    sleep 300
done