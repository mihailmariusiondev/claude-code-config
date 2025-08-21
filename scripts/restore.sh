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

# Merge inteligente de ~/.claude.json (solo sección mcpServers)
if [ -f "$CONFIG_DIR/.claude.json" ]; then
    if [ -f "$HOME/.claude.json" ]; then
        # Crear backup del archivo original
        cp "$HOME/.claude.json" "$HOME/.claude.json.backup"
        echo "💾 Backup creado: ~/.claude.json.backup"
        
        # Extraer solo mcpServers del archivo de configuración
        if python3 -c "
import json
import sys

# Leer archivo de configuración
with open('$CONFIG_DIR/.claude.json', 'r') as f:
    config_data = json.load(f)

# Leer archivo actual del usuario
with open('$HOME/.claude.json', 'r') as f:
    user_data = json.load(f)

# Solo reemplazar la sección mcpServers si existe en config
if 'mcpServers' in config_data:
    user_data['mcpServers'] = config_data['mcpServers']
    
    # Escribir archivo actualizado
    with open('$HOME/.claude.json', 'w') as f:
        json.dump(user_data, f, indent=2)
    
    print('success')
else:
    print('no_mcpservers')
" 2>/dev/null; then
            result=$(python3 -c "
import json
with open('$CONFIG_DIR/.claude.json', 'r') as f:
    config_data = json.load(f)
with open('$HOME/.claude.json', 'r') as f:
    user_data = json.load(f)
if 'mcpServers' in config_data:
    user_data['mcpServers'] = config_data['mcpServers']
    with open('$HOME/.claude.json', 'w') as f:
        json.dump(user_data, f, indent=2)
    print('success')
else:
    print('no_mcpservers')")
            
            if [ "$result" = "success" ]; then
                echo "✓ MCP Servers fusionados en ~/.claude.json (resto del archivo preservado)"
            else
                echo "⚠ No se encontró sección mcpServers en configuración"
            fi
        else
            echo "⚠ Error procesando archivos JSON con Python"
        fi
    else
        # Si no existe ~/.claude.json, copiar el archivo completo
        cp "$CONFIG_DIR/.claude.json" "$HOME/.claude.json"
        echo "✓ ~/.claude.json restaurado (archivo completo)"
    fi
else
    echo "⚠ No se encontró .claude.json en configuración"
fi

echo ""
echo "🎉 Configuración restaurada correctamente!"
echo ""
echo "Próximos pasos:"
echo "1. Ejecutar './scripts/install-service.sh' para activar sincronización automática"
echo "2. Ejecutar 'claude' para inicializar Claude Code si es necesario"
echo ""