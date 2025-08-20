#!/bin/bash

# Script para juntar toda la documentación de Claude Code en CLAUDE_RAW_DOCS.md
# Ejecutar con: bash ~/scripts/fetch-claude-docs.sh

echo "🔄 Fetching Claude Code documentation..."

# Archivo de salida
OUTPUT_FILE="$HOME/.claude/CLAUDE_RAW_DOCS.md"

# Crear archivo con header
cat > "$OUTPUT_FILE" << 'EOF'
# Claude Code - Documentación Completa RAW

Esta documentación se genera automáticamente desde https://docs.anthropic.com/en/docs/claude-code/

Última actualización: $(date)

---

EOF

# URLs de documentación
declare -a DOCS=(
    # Getting started
    "https://docs.anthropic.com/en/docs/claude-code/overview"
    "https://docs.anthropic.com/en/docs/claude-code/quickstart"
    "https://docs.anthropic.com/en/docs/claude-code/common-workflows"
    
    # Build with Claude Code
    "https://docs.anthropic.com/en/docs/claude-code/sdk"
    "https://docs.anthropic.com/en/docs/claude-code/sub-agents"
    "https://docs.anthropic.com/en/docs/claude-code/output-styles"
    "https://docs.anthropic.com/en/docs/claude-code/hooks-guide"
    "https://docs.anthropic.com/en/docs/claude-code/github-actions"
    "https://docs.anthropic.com/en/docs/claude-code/mcp"
    "https://docs.anthropic.com/en/docs/claude-code/troubleshooting"
    
    # Deployment
    "https://docs.anthropic.com/en/docs/claude-code/third-party-integrations"
    "https://docs.anthropic.com/en/docs/claude-code/amazon-bedrock"
    "https://docs.anthropic.com/en/docs/claude-code/corporate-proxy"
    "https://docs.anthropic.com/en/docs/claude-code/llm-gateway"
    "https://docs.anthropic.com/en/docs/claude-code/devcontainer"
    
    # Administration
    "https://docs.anthropic.com/en/docs/claude-code/setup"
    "https://docs.anthropic.com/en/docs/claude-code/iam"
    "https://docs.anthropic.com/en/docs/claude-code/security"
    "https://docs.anthropic.com/en/docs/claude-code/data-usage"
    "https://docs.anthropic.com/en/docs/claude-code/monitoring-usage"
    "https://docs.anthropic.com/en/docs/claude-code/costs"
    "https://docs.anthropic.com/en/docs/claude-code/analytics"
    
    # Configuration
    "https://docs.anthropic.com/en/docs/claude-code/settings"
    "https://docs.anthropic.com/en/docs/claude-code/ide-integrations"
    "https://docs.anthropic.com/en/docs/claude-code/terminal-config"
    "https://docs.anthropic.com/en/docs/claude-code/memory"
    "https://docs.anthropic.com/en/docs/claude-code/statusline"
    
    # Reference
    "https://docs.anthropic.com/en/docs/claude-code/cli-reference"
    "https://docs.anthropic.com/en/docs/claude-code/interactive-mode"
    "https://docs.anthropic.com/en/docs/claude-code/slash-commands"
    "https://docs.anthropic.com/en/docs/claude-code/hooks"
    
    # Resources
    "https://docs.anthropic.com/en/docs/claude-code/legal-and-compliance"
)

# Función para obtener el nombre de la sección desde la URL
get_section_name() {
    local url="$1"
    echo "$url" | sed 's|https://docs.anthropic.com/en/docs/claude-code/||' | sed 's|-| |g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1'
}

# Contador de progreso
total=${#DOCS[@]}
current=0

# Procesar cada URL
for url in "${DOCS[@]}"; do
    current=$((current + 1))
    section_name=$(get_section_name "$url")
    
    echo "📄 [$current/$total] Fetching: $section_name"
    
    # Agregar header de sección
    echo "" >> "$OUTPUT_FILE"
    echo "## $section_name" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "**URL:** $url" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Hacer curl y agregar contenido
    if curl -s "$url.md" >> "$OUTPUT_FILE" 2>/dev/null; then
        echo "✅ Success: $section_name"
    else
        echo "❌ Failed: $section_name - trying without .md extension"
        if curl -s "$url" >> "$OUTPUT_FILE" 2>/dev/null; then
            echo "✅ Success: $section_name (without .md)"
        else
            echo "❌ Failed completely: $section_name"
            echo "**ERROR: Could not fetch this documentation**" >> "$OUTPUT_FILE"
        fi
    fi
    
    # Agregar separador
    echo "" >> "$OUTPUT_FILE"
    echo "---" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Pausa pequeña para no sobrecargar el servidor
    sleep 0.1
done

echo ""
echo "✅ Documentación consolidada en: $OUTPUT_FILE"
echo "📊 Total secciones procesadas: $total"
echo ""
echo "Para ver el archivo:"
echo "  cat $OUTPUT_FILE | less"
echo ""
echo "Para editar el archivo:"
echo "  code $OUTPUT_FILE"