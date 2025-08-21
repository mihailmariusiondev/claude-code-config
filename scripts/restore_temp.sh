#!/bin/bash

# Claude Code Config Restore Script
# Restaura configuración en nueva máquina

REPO_DIR="/root/repos/claude-code-config"
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
    
    # Fusionar mcpServers
    jq --argjson mcps "$(cat "$CONFIG_DIR/mcpServers.json")" '.mcpServers = $mcps' "$HOME/.claude.json" > /tmp/claude-temp.json
    
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