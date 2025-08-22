#!/bin/bash
set -euo pipefail  # Strict mode: exit on error, undefined vars, pipe failures
# Claude Code Config Auto-Sync Script
# Sincroniza configuración cada 1 minuto

# Auto-detectar rutas dinámicas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"
CONFIG_DIR="$REPO_DIR/claude_config"
LOG_FILE="$REPO_DIR/logs/sync.log"

# Validar que estamos en un repo git
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "ERROR: Not in a git repository. Please run from claude-code-config directory." >&2
    exit 1
fi

# Crear directorios necesarios
if ! mkdir -p "$REPO_DIR/logs" "$CONFIG_DIR" 2>/dev/null; then
    echo "ERROR: Cannot create necessary directories. Check permissions." >&2
    exit 1
fi

if ! cd "$REPO_DIR" 2>/dev/null; then
    echo "ERROR: Cannot change to repository directory: $REPO_DIR" >&2
    exit 1
fi

# Función para logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" | tee -a "$LOG_FILE" >&2
}

# Limpiar log si es muy grande (>1MB)
if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt 1048576 ]; then
    if tail -n 100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 🧹 Log file rotated (kept last 100 lines)" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Failed to rotate log file" >&2
    fi
fi

# Trap para limpieza en caso de interrupción
cleanup() {
    log "=== Sync process interrupted, cleaning up ==="
    exit 0
}
trap cleanup SIGINT SIGTERM

log "=== Claude Code Config Auto-Sync Started ==="
log "Repository: $REPO_DIR"
log "Claude config: $CLAUDE_DIR"
log "Target config: $CONFIG_DIR"

# Verificar dependencias
if ! command -v git >/dev/null 2>&1; then
    error_log "git command not found. Please install git."
    exit 1
fi

while true; do
    log "Checking for changes..."

    # Copiar archivos directamente a claude_config/ con validación
    copy_file() {
        local src="$1"
        local dst="$2"
        local name="$3"

        if [ -f "$src" ] && [ -r "$src" ]; then
            if cp "$src" "$dst" 2>/dev/null; then
                log "✓ Copied $name"
                return 0
            else
                error_log "Failed to copy $name (permission or I/O error)"
                return 1
            fi
        fi
        return 0
    }

    copy_file "$CLAUDE_DIR/settings.json" "$CONFIG_DIR/settings.json" "settings.json"
    copy_file "$CLAUDE_DIR/CLAUDE.md" "$CONFIG_DIR/CLAUDE.md" "CLAUDE.md"
    copy_file "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md" "$CONFIG_DIR/CLAUDE_CODE_REFERENCE.md" "CLAUDE_CODE_REFERENCE.md"

    # Copiar archivo interno completo con validación JSON
    if [ -f "$HOME/.claude.json" ]; then
        if [ -r "$HOME/.claude.json" ]; then
            # Validar que es JSON válido antes de copiar
            if python3 -c "import json; json.load(open('$HOME/.claude.json'))" 2>/dev/null; then
                if cp "$HOME/.claude.json" "$CONFIG_DIR/.claude.json" 2>/dev/null; then
                    log "✓ Copied .claude.json (validated)"
                else
                    error_log "Failed to copy .claude.json (I/O error)"
                fi
            else
                error_log "Skipping .claude.json - invalid JSON format"
            fi
        else
            error_log "Cannot read ~/.claude.json (permission denied)"
        fi
    else
        log "⚠ ~/.claude.json not found - will be created when Claude Code runs"
    fi

    # Copiar directorios con validación
    copy_directory() {
        local src="$1"
        local dst="$2"
        local name="$3"

        if [ -d "$src" ] && [ -r "$src" ]; then
            if cp -r "$src" "$dst/" 2>/dev/null; then
                local count=$(find "$src" -type f | wc -l)
                log "✓ Copied $name directory ($count files)"
                return 0
            else
                error_log "Failed to copy $name directory"
                return 1
            fi
        fi
        return 0
    }

    copy_directory "$CLAUDE_DIR/commands" "$CONFIG_DIR" "commands"
    copy_directory "$CLAUDE_DIR/agents" "$CONFIG_DIR" "agents"

    # Verificar si hay cambios locales con mejor manejo de errores
    log "🔍 Checking for local git changes..."
    local_changes=false

    # Verificar que tenemos permisos de escritura
    if [ ! -w "$REPO_DIR" ]; then
        error_log "No write permissions in repository directory"
        continue
    fi

    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        local_changes=true
        log "📝 Local changes detected, preparing commit..."

        # Mostrar qué archivos cambiaron
        changed_files=$(git diff --name-only HEAD 2>/dev/null | head -5)
        if [ -n "$changed_files" ]; then
            log "Changed files: $(echo "$changed_files" | tr '\n' ' ')"
        fi

        if git add . 2>/dev/null; then
            log "✓ Files added to git staging"
            if git commit -m "auto-sync $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null; then
                log "✓ Local changes committed"
            else
                git_error=$(git commit -m "auto-sync $(date '+%Y-%m-%d %H:%M:%S')" 2>&1 || true)
                error_log "Failed to commit changes: $git_error"
            fi
        else
            error_log "Failed to add files to git staging"
        fi
    else
        log "💤 No local changes detected"
    fi

    # Push con mejor manejo de errores y reintentos
    log "🔄 Checking for commits to push..."

    # Verificar que hay commits para hacer push
    local_commits=$(git rev-list --count HEAD ^origin/main 2>/dev/null || echo "0")

    if [ "$local_commits" -gt 0 ]; then
        log "📤 Found $local_commits commit(s) to push..."

        # Intentar push normal primero, luego force si es necesario
        if git push origin main 2>/dev/null; then
            log "🚀 Changes pushed to GitHub successfully"
        else
            log "⚠ Normal push failed, attempting force push..."
            push_output=$(git push --force origin main 2>&1)
            if [ $? -eq 0 ]; then
                log "🚀 Changes force-pushed to GitHub successfully"
            else
                error_log "Failed to push to GitHub after retries"
                error_log "Git push error: $push_output"

                # Log network connectivity check
                if ping -c 1 github.com >/dev/null 2>&1; then
                    error_log "Network connectivity OK, may be authentication issue"
                else
                    error_log "Network connectivity issue detected"
                fi
            fi
        fi
    else
        log "💤 No local commits to push"
    fi

    # Esperar 5 minutos con posibilidad de interrupción
    log "⏱️ Waiting 1 minute until next sync..."

    # Sleep con señales manejables
    for i in {1..60}; do
        sleep 1
        # Verificar si el proceso debe terminar cada 60 segundos
        if [ $((i % 60)) -eq 0 ]; then
            # Verificar si el directorio sigue siendo válido
            if [ ! -d "$REPO_DIR" ]; then
                error_log "Repository directory disappeared: $REPO_DIR"
                exit 1
            fi
        fi
    done

    log "🔄 Starting next sync cycle..."
done

# Este punto nunca debería alcanzarse
log "=== Sync process ended unexpectedly ==="
exit 0
