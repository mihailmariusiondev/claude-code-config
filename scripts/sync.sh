#!/bin/bash

# Claude Code Config Auto-Sync Script
# Sincroniza configuración cada minuto

REPO_DIR="/home/mihai-usl/repos/personal/claude-code-config"
CLAUDE_DIR="$HOME/.claude"
TMP_DIR="$REPO_DIR/tmp"
CONFIG_DIR="$REPO_DIR/claude_config"
LOG_FILE="$REPO_DIR/logs/sync.log"

# Crear directorios necesarios
mkdir -p "$REPO_DIR/logs" "$TMP_DIR" "$CONFIG_DIR"

cd "$REPO_DIR"

# Función para logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" | tee -a "$LOG_FILE" >&2
}

# Limpiar log si es muy grande (>1MB)
if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt 1048576 ]; then
    tail -n 100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 🧹 Log file rotated (kept last 100 lines)" >> "$LOG_FILE"
fi

log "=== Claude Code Config Auto-Sync Started ==="

# Esperar 1 minuto antes del primer sync
log "⏱️ Waiting 1 minute before first sync..."
sleep 60

while true; do
    log "Checking for changes..."
    
    # Limpiar directorio temporal
    log "🧹 Cleaning tmp directory..."
    rm -rf "$TMP_DIR"/*
    log "✓ Tmp directory cleaned"
    
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
    log "📁 Syncing tmp/ to claude_config/..."
    if [ "$(ls -A "$TMP_DIR" 2>/dev/null)" ]; then
        rsync -av --delete "$TMP_DIR/" "$CONFIG_DIR/" 2>/dev/null && log "✓ Synced to claude_config/" || error_log "Failed to sync to claude_config/"
    else
        log "⚠ No files in tmp/ to sync"
    fi
    
    # Verificar si hay cambios locales
    log "🔍 Checking for local git changes..."
    local_changes=false
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        local_changes=true
        log "📝 Local changes detected, preparing commit..."
        if git add . 2>/dev/null; then
            log "✓ Files added to git staging"
            if git commit -m "auto-sync $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null; then
                log "✓ Local changes committed"
            else
                error_log "Failed to commit changes"
            fi
        else
            error_log "Failed to add files to git"
        fi
    else
        log "💤 No local changes detected"
    fi
    
    # Siempre intentar push si hay commits locales (sin depender de origin/main)
    log "🔄 Checking for commits to push..."
    if git log --oneline -1 2>/dev/null | grep -q .; then
        log "📤 Commits found, attempting force push to GitHub..."
        # Push directo con --force
        if git push --force origin main 2>/dev/null; then
            log "🚀 Changes force-pushed to GitHub successfully"
        else
            error_log "Failed to force push to GitHub"
            log "🔍 Debugging push failure..."
            git remote -v | while read line; do log "Remote: $line"; done
            git status --porcelain | while read line; do log "Status: $line"; done
        fi
    elif [ "$local_changes" = true ]; then
        log "✓ Local changes committed but already synced"
    else
        log "💤 No changes detected"
    fi
    
    # Esperar 1 minuto
    log "⏱️ Waiting 1 minute until next sync..."
    sleep 60
    log "🔄 Starting next sync cycle..."
done