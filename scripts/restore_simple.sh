#!/bin/bash
set -euo pipefail

# Script simplificado para restaurar configuración Claude Code
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"
CONFIG_DIR="$REPO_DIR/claude_config"

echo "🔄 Restaurando configuración Claude Code..."
echo "Fuente: $CONFIG_DIR"
echo "Destino: $CLAUDE_DIR"

# Crear directorio si no existe
mkdir -p "$CLAUDE_DIR"

# Copiar archivos principales
echo "📄 Copiando archivos principales..."

if [ -f "$CONFIG_DIR/settings.json" ]; then
    cp "$CONFIG_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    echo "✅ settings.json copiado"
else
    echo "⚠️ settings.json no encontrado"
fi

if [ -f "$CONFIG_DIR/CLAUDE.md" ]; then
    cp "$CONFIG_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    echo "✅ CLAUDE.md copiado"
else
    echo "⚠️ CLAUDE.md no encontrado"
fi

if [ -f "$CONFIG_DIR/CLAUDE_CODE_REFERENCE.md" ]; then
    cp "$CONFIG_DIR/CLAUDE_CODE_REFERENCE.md" "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md"
    echo "✅ CLAUDE_CODE_REFERENCE.md copiado"
else
    echo "⚠️ CLAUDE_CODE_REFERENCE.md no encontrado"
fi

# Copiar directorios si existen
if [ -d "$CONFIG_DIR/commands" ]; then
    cp -r "$CONFIG_DIR/commands" "$CLAUDE_DIR/"
    echo "✅ Directorio commands/ copiado"
fi

if [ -d "$CONFIG_DIR/agents" ]; then
    cp -r "$CONFIG_DIR/agents" "$CLAUDE_DIR/"
    echo "✅ Directorio agents/ copiado"
fi

# Procesar .claude.json si existe
if [ -f "$CONFIG_DIR/.claude.json" ]; then
    echo "📋 Procesando .claude.json..."
    
    # Validar JSON
    if python3 -c "import json; json.load(open('$CONFIG_DIR/.claude.json'))" 2>/dev/null; then
        if [ -f "$HOME/.claude.json" ]; then
            # Hacer backup único (sobrescribe el anterior)
            if [ ! -f "$HOME/.claude.json.backup" ]; then
                cp "$HOME/.claude.json" "$HOME/.claude.json.backup"
                echo "✅ Backup inicial creado de ~/.claude.json"
            else
                echo "✅ Manteniendo backup existente"
            fi
            
            # Merge inteligente: solo reemplazar mcpServers
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
        print('✅ mcpServers fusionados en ~/.claude.json')
    else:
        print('⚠️ No hay mcpServers en configuración')
except Exception as e:
    print(f'❌ Error: {e}')
    exit(1)
"
        else
            # Copiar completo
            cp "$CONFIG_DIR/.claude.json" "$HOME/.claude.json"
            chmod 600 "$HOME/.claude.json"
            echo "✅ ~/.claude.json copiado completamente"
        fi
    else
        echo "❌ .claude.json no es válido"
    fi
else
    echo "⚠️ .claude.json no encontrado en configuración"
fi

# Ajustar permisos
chmod 755 "$CLAUDE_DIR" 2>/dev/null || true
find "$CLAUDE_DIR" -type f -exec chmod 644 {} \; 2>/dev/null || true
find "$CLAUDE_DIR" -type d -exec chmod 755 {} \; 2>/dev/null || true

echo ""
echo "🎉 ¡Configuración restaurada!"
echo ""
echo "📋 Archivos restaurados:"
ls -la "$CLAUDE_DIR" | grep "^-" | while read line; do
    echo "  $line"
done

if [ -f "$HOME/.claude.json" ]; then
    servers=$(python3 -c "
try:
    import json
    with open('$HOME/.claude.json', 'r') as f:
        data = json.load(f)
    print(len(data.get('mcpServers', {})))
except: 
    print('error')
" 2>/dev/null)
    echo ""
    echo "📊 ~/.claude.json: $servers MCP servers configurados"
fi

echo ""
echo "✅ Configuración lista para usar con Claude Code"