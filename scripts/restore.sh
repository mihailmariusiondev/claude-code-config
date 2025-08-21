#!/bin/bash
set -euo pipefail

# Script de restauración DEFINITIVO - SIN LOGGING COMPLEJO
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"
CONFIG_DIR="$REPO_DIR/claude_config"

echo "🔄 Restaurando configuración Claude Code..."
echo "Fuente: $CONFIG_DIR"
echo "Destino: $CLAUDE_DIR"

# Crear directorio
mkdir -p "$CLAUDE_DIR"

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

# Copiar archivos principales SIN LOGGING COMPLEJO
copy_file "$CONFIG_DIR/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"
copy_file "$CONFIG_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md"  
copy_file "$CONFIG_DIR/CLAUDE_CODE_REFERENCE.md" "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md" "CLAUDE_CODE_REFERENCE.md"

# Copiar directorios si existen
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

# Procesar .claude.json SIMPLE
if [ -f "$CONFIG_DIR/.claude.json" ]; then
    echo "📋 Procesando .claude.json..."
    
    if python3 -c "import json; json.load(open('$CONFIG_DIR/.claude.json'))" 2>/dev/null; then
        if [ -f "$HOME/.claude.json" ]; then
            # Backup único
            if [ ! -f "$HOME/.claude.json.backup" ]; then
                cp "$HOME/.claude.json" "$HOME/.claude.json.backup"
                echo "✅ Backup creado"
            fi
            
            # Merge simple
            python3 -c "
import json
try:
    with open('$CONFIG_DIR/.claude.json', 'r') as f:
        config_data = json.load(f)
    
    with open('$HOME/.claude.json', 'r') as f:
        user_data = json.load(f)
    
    if 'mcpServers' in config_data:
        user_data['mcpServers'] = config_data['mcpServers']
        
        with open('$HOME/.claude.json', 'w') as f:
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
            cp "$CONFIG_DIR/.claude.json" "$HOME/.claude.json"
            chmod 600 "$HOME/.claude.json"
            echo "✅ .claude.json copiado"
        fi
    else
        echo "❌ .claude.json inválido"
    fi
fi

echo ""
echo "🎉 ¡Configuración restaurada!"
echo "✅ Script completado exitosamente"