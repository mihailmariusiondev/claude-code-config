#!/bin/bash

# Claude Code Config Auto-Sync Script
# Sincroniza configuración cada 5 minutos

# Auto-detectar rutas dinámicas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"
CONFIG_DIR="$REPO_DIR/claude_config"
LOG_FILE="$REPO_DIR/logs/sync.log"

# Crear directorios necesarios
mkdir -p "$REPO_DIR/logs" "$CONFIG_DIR"

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

while true; do
    log "Checking for changes..."
    
    # Copiar archivos directamente a claude_config/
    if [ -f "$CLAUDE_DIR/settings.json" ]; then
        cp "$CLAUDE_DIR/settings.json" "$CONFIG_DIR/" 2>/dev/null && log "✓ Copied settings.json" || error_log "Failed to copy settings.json"
    fi
    
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        cp "$CLAUDE_DIR/CLAUDE.md" "$CONFIG_DIR/" 2>/dev/null && log "✓ Copied CLAUDE.md" || error_log "Failed to copy CLAUDE.md"
    fi
    
    if [ -f "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md" ]; then
        cp "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md" "$CONFIG_DIR/" 2>/dev/null && log "✓ Copied CLAUDE_CODE_REFERENCE.md" || error_log "Failed to copy CLAUDE_CODE_REFERENCE.md"
    fi
    
    # Copiar archivo interno completo (mismo nombre)
    if [ -f "$HOME/.claude.json" ]; then
        if [ -r "$HOME/.claude.json" ]; then
            if cp "$HOME/.claude.json" "$CONFIG_DIR/.claude.json" 2>/dev/null; then
                log "✓ Copied .claude.json"
            else
                error_log "Failed to copy .claude.json"
            fi
        else
            error_log "Cannot read ~/.claude.json (permission denied)"
        fi
    else
        log "⚠ ~/.claude.json not found"
    fi
    
    # Copiar directorios commands/ y agents/ si existen
    if [ -d "$CLAUDE_DIR/commands" ]; then
        cp -r "$CLAUDE_DIR/commands" "$CONFIG_DIR/" 2>/dev/null && log "✓ Copied commands directory" || error_log "Failed to copy commands directory"
    fi
    
    if [ -d "$CLAUDE_DIR/agents" ]; then
        cp -r "$CLAUDE_DIR/agents" "$CONFIG_DIR/" 2>/dev/null && log "✓ Copied agents directory" || error_log "Failed to copy agents directory"
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
    
    # Siempre intentar push si hay commits locales
    log "🔄 Checking for commits to push..."
    if git log --oneline -1 2>/dev/null | grep -q .; then
        log "📤 Commits found, attempting force push to GitHub..."
        push_output=$(git push --force origin main 2>&1)
        if [ $? -eq 0 ]; then
            log "🚀 Changes force-pushed to GitHub successfully"
        else
            error_log "Failed to force push to GitHub"
            error_log "Git push error output: $push_output"
        fi
    else
        log "💤 No changes detected"
    fi
    
    # Esperar 5 minutos
    log "⏱️ Waiting 5 minutes until next sync..."
    sleep 300
    log "🔄 Starting next sync cycle..."
done