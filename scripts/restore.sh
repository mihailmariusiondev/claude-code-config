#!/bin/bash

# Claude Code Config Restore Script
# Restaura configuración en nueva máquina

REPO_DIR="/home/mihai-usl/repos/personal/claude-code-config"
CLAUDE_DIR="$HOME/.claude"

echo "Restaurando configuración Claude Code..."

# Crear directorio ~/.claude si no existe
mkdir -p "$CLAUDE_DIR"

cd "$REPO_DIR"

# Restaurar archivos principales
if [ -f "settings.json" ]; then
    cp "settings.json" "$CLAUDE_DIR/"
    echo "✓ settings.json restaurado"
fi

if [ -f "CLAUDE.md" ]; then
    cp "CLAUDE.md" "$CLAUDE_DIR/"
    echo "✓ CLAUDE.md restaurado"
fi

if [ -f "CLAUDE_CODE_REFERENCE.md" ]; then
    cp "CLAUDE_CODE_REFERENCE.md" "$CLAUDE_DIR/"
    echo "✓ CLAUDE_CODE_REFERENCE.md restaurado"
fi

if [ -f "fetch-claude-docs.sh" ]; then
    cp "fetch-claude-docs.sh" "$CLAUDE_DIR/"
    chmod +x "$CLAUDE_DIR/fetch-claude-docs.sh"
    echo "✓ fetch-claude-docs.sh restaurado"
fi

# Restaurar directorios commands/ y agents/ si existen
if [ -d "commands" ]; then
    cp -r "commands" "$CLAUDE_DIR/"
    echo "✓ Comandos personalizados restaurados"
fi

if [ -d "agents" ]; then
    cp -r "agents" "$CLAUDE_DIR/"
    echo "✓ Agentes personalizados restaurados"
fi

# Fusionar mcpServers en ~/.claude.json si existe
if [ -f "mcpServers.json" ] && [ -f "$HOME/.claude.json" ]; then
    # Crear backup del archivo original
    cp "$HOME/.claude.json" "$HOME/.claude.json.backup"
    
    # Fusionar mcpServers
    jq --argjson mcps "$(cat mcpServers.json)" '.mcpServers = $mcps' "$HOME/.claude.json" > /tmp/claude-temp.json
    
    if [ $? -eq 0 ]; then
        mv /tmp/claude-temp.json "$HOME/.claude.json"
        echo "✓ MCP Servers restaurados en ~/.claude.json"
    else
        echo "⚠ Error fusionando MCPs, archivo original respaldado en ~/.claude.json.backup"
    fi
elif [ -f "mcpServers.json" ]; then
    echo "⚠ ~/.claude.json no existe aún, MCPs se aplicarán cuando Claude Code cree el archivo"
fi

echo ""
echo "🎉 Configuración restaurada correctamente!"
echo ""
echo "Próximos pasos:"
echo "1. Ejecutar './scripts/install-service.sh' para activar sincronización automática"
echo "2. Ejecutar 'claude' si es necesario para inicializar Claude Code"
echo ""