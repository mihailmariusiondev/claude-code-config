#!/bin/bash

# Claude Code Config Restore Script
# Restaura configuración en nueva máquina

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
CONFIG_DIR="$REPO_DIR/claude_config"

echo "Restaurando configuración Claude Code..."

# Crear directorio ~/.claude si no existe
mkdir -p "$CLAUDE_DIR"

cd "$REPO_DIR"

# Restaurar archivos principales desde claude_config/
if [ -f "$CONFIG_DIR/settings.json" ]; then
    cp "$CONFIG_DIR/settings.json" "$CLAUDE_DIR/"
    echo "✓ settings.json restaurado"
fi

if [ -f "$CONFIG_DIR/CLAUDE.md" ]; then
    cp "$CONFIG_DIR/CLAUDE.md" "$CLAUDE_DIR/"
    echo "✓ CLAUDE.md restaurado"
fi

if [ -f "$CONFIG_DIR/CLAUDE_CODE_REFERENCE.md" ]; then
    cp "$CONFIG_DIR/CLAUDE_CODE_REFERENCE.md" "$CLAUDE_DIR/"
    echo "✓ CLAUDE_CODE_REFERENCE.md restaurado"
fi

# Restaurar directorios commands/ y agents/ desde claude_config/ si existen
if [ -d "$CONFIG_DIR/commands" ]; then
    cp -r "$CONFIG_DIR/commands" "$CLAUDE_DIR/"
    echo "✓ Comandos personalizados restaurados"
fi

if [ -d "$CONFIG_DIR/agents" ]; then
    cp -r "$CONFIG_DIR/agents" "$CLAUDE_DIR/"
    echo "✓ Agentes personalizados restaurados"
fi

# Fusionar mcpServers en ~/.claude.json si existe
if [ -f "$CONFIG_DIR/mcpServers.json" ] && [ -f "$HOME/.claude.json" ]; then
    # Crear backup del archivo original
    cp "$HOME/.claude.json" "$HOME/.claude.json.backup"
    
    # Fusionar mcpServers usando Python (más universal que jq)
    python3 -c "
import json
import sys

try:
    # Leer archivo principal
    with open('$HOME/.claude.json', 'r') as f:
        main_config = json.load(f)
    
    # Leer mcpServers
    with open('$CONFIG_DIR/mcpServers.json', 'r') as f:
        mcp_servers = json.load(f)
    
    # Fusionar
    main_config['mcpServers'] = mcp_servers
    
    # Escribir resultado
    with open('/tmp/claude-temp.json', 'w') as f:
        json.dump(main_config, f, indent=2)
    
    print('success')
except Exception as e:
    print(f'error: {e}', file=sys.stderr)
    sys.exit(1)
"
    
    if [ $? -eq 0 ]; then
        mv /tmp/claude-temp.json "$HOME/.claude.json"
        echo "✓ MCP Servers restaurados en ~/.claude.json"
    else
        echo "⚠ Error fusionando MCPs, archivo original respaldado en ~/.claude.json.backup"
    fi
elif [ -f "$CONFIG_DIR/mcpServers.json" ]; then
    echo "⚠ ~/.claude.json no existe aún, MCPs se aplicarán cuando Claude Code cree el archivo"
fi

echo ""
echo "🎉 Configuración restaurada correctamente!"
echo ""
echo "Próximos pasos:"
echo "1. Ejecutar './scripts/install-service.sh' para activar sincronización automática"
echo "2. Ejecutar 'claude' si es necesario para inicializar Claude Code"
echo ""