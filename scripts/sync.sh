#!/bin/bash

# Claude Code Config Auto-Sync Script
# Sincroniza configuración cada minuto

REPO_DIR="/home/mihai-usl/repos/personal/claude-code-config"
CLAUDE_DIR="$HOME/.claude"
TMP_DIR="$REPO_DIR/tmp"
CONFIG_DIR="$REPO_DIR/claude_config"
LOG_FILE="$REPO_DIR/logs/sync.log"
ERROR_LOG="$REPO_DIR/logs/error.log"

# Crear directorios necesarios
mkdir -p "$REPO_DIR/logs" "$TMP_DIR" "$CONFIG_DIR"

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
    
    # Limpiar directorio temporal
    rm -rf "$TMP_DIR"/*
    
    # Copiar archivos principales de configuración a tmp/
    if [ -f "$CLAUDE_DIR/settings.json" ]; then
        cp "$CLAUDE_DIR/settings.json" "$TMP_DIR/" 2>/dev/null && log "✓ Staged settings.json" || error_log "Failed to stage settings.json"
    fi
    
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        cp "$CLAUDE_DIR/CLAUDE.md" "$TMP_DIR/" 2>/dev/null && log "✓ Staged CLAUDE.md" || error_log "Failed to stage CLAUDE.md"
    fi
    
    if [ -f "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md" ]; then
        cp "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md" "$TMP_DIR/" 2>/dev/null && log "✓ Staged CLAUDE_CODE_REFERENCE.md" || error_log "Failed to stage CLAUDE_CODE_REFERENCE.md"
    fi
    
    # Extraer solo sección mcpServers de ~/.claude.json a tmp/
    if [ -f "$HOME/.claude.json" ]; then
        if [ -r "$HOME/.claude.json" ]; then
            if timeout 5 jq '.mcpServers // {}' "$HOME/.claude.json" > "$TMP_DIR/mcpServers.json" 2>/dev/null; then
                log "✓ Staged mcpServers.json ($(jq length "$TMP_DIR/mcpServers.json") servers)"
            else
                echo "{}" > "$TMP_DIR/mcpServers.json"
                error_log "Failed to extract mcpServers (timeout or parse error), created empty file"
            fi
        else
            echo "{}" > "$TMP_DIR/mcpServers.json"
            error_log "Cannot read ~/.claude.json (permission denied), created empty file"
        fi
    else
        echo "{}" > "$TMP_DIR/mcpServers.json"
        log "⚠ ~/.claude.json not found, created empty mcpServers.json"
    fi
    
    # Copiar directorios commands/ y agents/ a tmp/ si existen
    if [ -d "$CLAUDE_DIR/commands" ]; then
        cp -r "$CLAUDE_DIR/commands" "$TMP_DIR/" 2>/dev/null && log "✓ Staged commands directory" || error_log "Failed to stage commands directory"
    fi
    
    if [ -d "$CLAUDE_DIR/agents" ]; then
        cp -r "$CLAUDE_DIR/agents" "$TMP_DIR/" 2>/dev/null && log "✓ Staged agents directory" || error_log "Failed to stage agents directory"
    fi
    
    # Mover archivos desde tmp/ a claude_config/
    if [ "$(ls -A "$TMP_DIR" 2>/dev/null)" ]; then
        rsync -av --delete "$TMP_DIR/" "$CONFIG_DIR/" 2>/dev/null && log "✓ Synced to claude_config/" || error_log "Failed to sync to claude_config/"
    fi
    
    # Verificar si hay cambios locales
    local_changes=false
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        local_changes=true
        if git add . 2>/dev/null; then
            if git commit -m "auto-sync $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null; then
                log "✓ Local changes committed"
            else
                error_log "Failed to commit changes"
            fi
        else
            error_log "Failed to add files to git"
        fi
    fi
    
    # Siempre intentar push si hay commits locales (sin depender de origin/main)
    if git log --oneline -1 2>/dev/null | grep -q .; then
        # Push directo con --force
        if git push --force origin main 2>/dev/null; then
            log "🚀 Changes force-pushed to GitHub successfully"
        else
            error_log "Failed to force push to GitHub"
        fi
    elif [ "$local_changes" = true ]; then
        log "✓ Local changes committed but already synced"
    else
        log "💤 No changes detected"
    fi
    
    # Esperar 1 minuto
    sleep 60
done