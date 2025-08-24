#!/bin/bash
# ==================================================================================
# CLAUDE CODE STATUSLINE PERFECCIONADO - INTEGRACIÓN COMPLETA CCUSAGE
# ==================================================================================
# Versión: 3.0 - Full ccusage integration
# Fecha: 2025-08-22
# ==================================================================================

# COLORES PROFESIONALES - Paleta coherente
C_RESET='\033[0m'

# Sistema y tiempo
C_TIME='\033[38;5;245m'          # Gris medio
C_DIR='\033[38;5;75m'            # Azul cielo
C_TERMINAL='\033[38;5;240m'      # Gris oscuro

# Git - Verde/Amarillo/Rojo
C_BRANCH='\033[38;5;180m'        # Beige branch
C_GIT_OK='\033[38;5;65m'         # Verde apagado
C_GIT_WARN='\033[38;5;172m'      # Amarillo apagado
C_GIT_DANGER='\033[38;5;124m'    # Rojo apagado
C_GIT_NEUTRAL='\033[38;5;240m'   # Gris neutro

# Contexto - Gradiente verde a rojo
C_CTX_LOW='\033[38;5;65m'        # Verde bosque
C_CTX_MED='\033[38;5;172m'       # Amarillo dorado
C_CTX_HIGH='\033[38;5;166m'      # Naranja apagado
C_CTX_CRITICAL='\033[38;5;124m'  # Rojo ladrillo

# Métricas y costos
C_MODEL='\033[38;5;141m'         # Púrpura suave
C_COST='\033[38;5;178m'          # Dorado suave
C_COUNT='\033[38;5;73m'          # Cyan apagado
C_SESSION='\033[38;5;96m'        # Magenta apagado

# ==================================================================================
# ENTRADA Y DATOS BÁSICOS
# ==================================================================================

input=$(cat)
CURRENT_TIME=$(date '+%H:%M')
CURRENT_USER=$(whoami)
CURRENT_PATH=$(pwd)
CURRENT_DIR=$(basename "$CURRENT_PATH")
TERMINAL_WIDTH=$(tput cols 2>/dev/null || echo "80")

# Formatear path (acortar si es muy largo)
if [ "${#CURRENT_PATH}" -gt 40 ]; then
    # Mostrar solo los últimos 3 directorios
    SHORT_PATH=$(echo "$CURRENT_PATH" | awk -F'/' '{if(NF>3) print "..."$(NF-2)"/"$(NF-1)"/"$NF; else print $0}')
else
    SHORT_PATH="$CURRENT_PATH"
fi

# Color dinámico para directorio
if [[ "$CURRENT_PATH" == *"/repos/"* ]]; then
    DIR_COLOR=$C_GIT_OK
elif [[ "$CURRENT_PATH" == "$HOME" ]]; then
    DIR_COLOR=$C_DIR
elif [[ "$CURRENT_PATH" == "/"* ]]; then
    DIR_COLOR=$C_TERMINAL
else
    DIR_COLOR=$C_DIR
fi

# ==================================================================================
# GIT STATUS INTELIGENTE
# ==================================================================================

if git rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
    
    # Ahead/Behind
    UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    if [ -n "$UPSTREAM" ]; then
        AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
        BEHIND=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
    else
        AHEAD="0"; BEHIND="0"
    fi
    
    # Cambios
    ADDED=$(git status --porcelain 2>/dev/null | grep "^A" | wc -l | tr -d ' ')
    MODIFIED=$(git status --porcelain 2>/dev/null | grep "^.M" | wc -l | tr -d ' ')
    DELETED=$(git status --porcelain 2>/dev/null | grep "^.D" | wc -l | tr -d ' ')
    
    # Status por magnitud
    TOTAL_CHANGES=$((ADDED + MODIFIED + DELETED))
    if [ "$TOTAL_CHANGES" -gt 15 ]; then
        GIT_STATUS="${C_GIT_DANGER}HOT${C_RESET}"
    elif [ "$TOTAL_CHANGES" -gt 5 ]; then
        GIT_STATUS="${C_GIT_WARN}WIP${C_RESET}"
    elif [ "$TOTAL_CHANGES" -gt 0 ]; then
        GIT_STATUS="${C_GIT_WARN}MOD${C_RESET}"
    else
        GIT_STATUS="${C_GIT_OK}CLEAN${C_RESET}"
    fi
    
    # Colores dinámicos
    UP_COLOR=$([[ "$AHEAD" -gt 0 ]] && echo "$C_GIT_OK" || echo "$C_GIT_NEUTRAL")
    DOWN_COLOR=$([[ "$BEHIND" -gt 0 ]] && echo "$C_GIT_DANGER" || echo "$C_GIT_NEUTRAL")
    ADD_COLOR=$([[ "$ADDED" -gt 0 ]] && echo "$C_GIT_OK" || echo "$C_GIT_NEUTRAL")
    MOD_COLOR=$([[ "$MODIFIED" -gt 0 ]] && echo "$C_GIT_WARN" || echo "$C_GIT_NEUTRAL")
    DEL_COLOR=$([[ "$DELETED" -gt 0 ]] && echo "$C_GIT_DANGER" || echo "$C_GIT_NEUTRAL")
else
    BRANCH="no-git"
    AHEAD="0"; BEHIND="0"; ADDED="0"; MODIFIED="0"; DELETED="0"
    GIT_STATUS="${C_GIT_NEUTRAL}---${C_RESET}"
    UP_COLOR=$C_GIT_NEUTRAL; DOWN_COLOR=$C_GIT_NEUTRAL
    ADD_COLOR=$C_GIT_NEUTRAL; MOD_COLOR=$C_GIT_NEUTRAL; DEL_COLOR=$C_GIT_NEUTRAL
fi

# ==================================================================================
# CCUSAGE INTEGRATION - Adaptador mejorado
# ==================================================================================

# Extraer datos esenciales del JSON de Claude Code
SESSION_ID=$(echo "$input" | jq -r '.session_id // "unknown"')
TRANSCRIPT_PATH=$(echo "$input" | jq -r '.transcript_path // ""')
MODEL_ID=$(echo "$input" | jq -r '.model.id // "claude-3-5-sonnet"')
MODEL_NAME=$(echo "$input" | jq -r '.model.display_name // .model // "Unknown"')

# Simplificar nombre del modelo
MODEL=$(echo "$MODEL_NAME" | sed 's/Claude //g' | sed 's/Sonnet/S/g' | sed 's/Opus/O/g' | sed 's/ //g')

# Datos de costo
SESSION_COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
INPUT_TOKENS=$(echo "$input" | jq -r '.cost.input_tokens // 0')
OUTPUT_TOKENS=$(echo "$input" | jq -r '.cost.output_tokens // 0')
CACHE_CREATE=$(echo "$input" | jq -r '.cost.cache_creation_tokens // 0')
CACHE_READ=$(echo "$input" | jq -r '.cost.cache_read_tokens // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Construir JSON para ccusage
CCUSAGE_JSON=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "transcript_path": "$TRANSCRIPT_PATH",
  "cwd": "$(pwd)",
  "model": {
    "id": "$MODEL_ID",
    "display_name": "$MODEL_NAME"
  },
  "workspace": {
    "current_dir": "$(pwd)",
    "project_dir": "$(pwd)"
  },
  "cost": {
    "total_cost_usd": $SESSION_COST,
    "input_tokens": $INPUT_TOKENS,
    "output_tokens": $OUTPUT_TOKENS,
    "cache_creation_tokens": $CACHE_CREATE,
    "cache_read_tokens": $CACHE_READ
  }
}
EOF
)

# Ejecutar ccusage con opciones optimizadas
CCUSAGE_OUTPUT=$(echo "$CCUSAGE_JSON" | npx ccusage statusline \
    --visual-burn-rate emoji \
    --cost-source both \
    --offline \
    2>/dev/null || echo "")

# ==================================================================================
# PROCESAR SALIDA DE CCUSAGE
# ==================================================================================

if [ -n "$CCUSAGE_OUTPUT" ] && [[ "$CCUSAGE_OUTPUT" != *"Error"* ]]; then
    # Extraer métricas de ccusage
    SESSION_COST_CC=$(echo "$CCUSAGE_OUTPUT" | grep -oE '\$[0-9]+\.[0-9]+ cc' | sed 's/ cc//' | head -1)
    SESSION_COST_CALC=$(echo "$CCUSAGE_OUTPUT" | grep -oE '\$[0-9]+\.[0-9]+ ccusage' | sed 's/ ccusage//' | head -1)
    TODAY_COST=$(echo "$CCUSAGE_OUTPUT" | grep -oE '\$[0-9]+\.[0-9]+ today' | sed 's/ today//' | head -1)
    BLOCK_COST=$(echo "$CCUSAGE_OUTPUT" | grep -oE '\$[0-9]+\.[0-9]+ block' | sed 's/ block//' | head -1)
    BLOCK_TIME=$(echo "$CCUSAGE_OUTPUT" | grep -oE '\([0-9]+h [0-9]+m left\)' | sed 's/[()]//g' | head -1)
    BURN_RATE=$(echo "$CCUSAGE_OUTPUT" | grep -oE '\$[0-9]+\.[0-9]+/hr' | head -1)
    CONTEXT_INFO=$(echo "$CCUSAGE_OUTPUT" | grep -oE '[0-9,]+ \([0-9]+%\)' | head -1)
    
    # Usar el costo de sesión más confiable
    if [ -n "$SESSION_COST_CALC" ]; then
        SESSION_FINAL="$SESSION_COST_CALC"
    elif [ -n "$SESSION_COST_CC" ]; then
        SESSION_FINAL="$SESSION_COST_CC"
    else
        SESSION_FINAL=$(printf '$%.2f' "$SESSION_COST")
    fi
    
    CCUSAGE_AVAILABLE=true
else
    # Fallback: calcular métricas localmente
    CCUSAGE_AVAILABLE=false
    SESSION_FINAL=$(printf '$%.2f' "$SESSION_COST")
    
    # Calcular duración
    if [ "$DURATION_MS" -gt 0 ]; then
        DURATION_MIN=$((DURATION_MS / 60000))
        DURATION_FMT="${DURATION_MIN}m"
    else
        DURATION_FMT="0m"
    fi
    
    # Calcular contexto aproximado
    TOTAL_TOKENS=$((INPUT_TOKENS + OUTPUT_TOKENS))
    if [ "$TOTAL_TOKENS" -gt 0 ]; then
        # Estimar contexto (asumiendo límite de 200K para Sonnet)
        MAX_CONTEXT=200000
        CONTEXT_PCT=$((TOTAL_TOKENS * 100 / MAX_CONTEXT))
        CONTEXT_INFO="${TOTAL_TOKENS} (${CONTEXT_PCT}%)"
    fi
fi

# ==================================================================================
# EMOJIS Y COLORES INTELIGENTES
# ==================================================================================

# Emoji y color por burn rate
if [[ "$BURN_RATE" =~ \$([0-9]+) ]]; then
    RATE_NUM=${BASH_REMATCH[1]}
    if [ "$RATE_NUM" -gt 10 ]; then
        BURN_COLOR=$C_GIT_DANGER; BURN_EMOJI="🔥"
    elif [ "$RATE_NUM" -gt 5 ]; then
        BURN_COLOR=$C_GIT_WARN; BURN_EMOJI="⚡"
    else
        BURN_COLOR=$C_GIT_OK; BURN_EMOJI="💚"
    fi
else
    BURN_COLOR=$C_GIT_NEUTRAL; BURN_EMOJI="📊"
fi

# Emoji y color por contexto
if [[ "$CONTEXT_INFO" =~ \(([0-9]+)%\) ]]; then
    CTX_PCT=${BASH_REMATCH[1]}
    if [ "$CTX_PCT" -gt 90 ]; then
        CTX_COLOR=$C_CTX_CRITICAL; CTX_EMOJI="🔴"
    elif [ "$CTX_PCT" -gt 75 ]; then
        CTX_COLOR=$C_CTX_HIGH; CTX_EMOJI="🟠"
    elif [ "$CTX_PCT" -gt 50 ]; then
        CTX_COLOR=$C_CTX_MED; CTX_EMOJI="🟡"
    else
        CTX_COLOR=$C_CTX_LOW; CTX_EMOJI="🟢"
    fi
else
    CTX_COLOR=$C_GIT_NEUTRAL; CTX_EMOJI="⚪"
fi

# Emoji y color por tiempo restante del bloque
if [[ "$BLOCK_TIME" =~ ([0-9]+)h ]]; then
    HOURS_LEFT=${BASH_REMATCH[1]}
    if [ "$HOURS_LEFT" -lt 1 ]; then
        BLOCK_COLOR=$C_GIT_DANGER; TIME_EMOJI="⏰"
    elif [ "$HOURS_LEFT" -lt 2 ]; then
        BLOCK_COLOR=$C_GIT_WARN; TIME_EMOJI="⏲"
    else
        BLOCK_COLOR=$C_GIT_OK; TIME_EMOJI="⏱"
    fi
else
    BLOCK_COLOR=$C_GIT_NEUTRAL; TIME_EMOJI="🕐"
fi

# Color por costo de sesión
if [[ "$SESSION_FINAL" =~ \$([0-9]+) ]]; then
    COST_NUM=${BASH_REMATCH[1]}
    if [ "$COST_NUM" -gt 5 ]; then
        SESSION_COLOR=$C_GIT_DANGER
    elif [ "$COST_NUM" -gt 2 ]; then
        SESSION_COLOR=$C_GIT_WARN
    else
        SESSION_COLOR=$C_GIT_OK
    fi
else
    SESSION_COLOR=$C_COST
fi

# ==================================================================================
# OUTPUT FINAL - 3 LÍNEAS LIMPIAS
# ==================================================================================

# Línea 1: Sistema y Git con ruta completa
echo -e "${C_TIME}${CURRENT_TIME}${C_RESET} ${C_TERMINAL}${CURRENT_USER}${C_RESET} ${DIR_COLOR}${SHORT_PATH}${C_RESET} ${C_BRANCH}${BRANCH}${C_RESET} ${UP_COLOR}↑${AHEAD}${C_RESET} ${DOWN_COLOR}↓${BEHIND}${C_RESET} ${ADD_COLOR}+${ADDED}${C_RESET} ${MOD_COLOR}~${MODIFIED}${C_RESET} ${DEL_COLOR}-${DELETED}${C_RESET} ${GIT_STATUS} ${C_TERMINAL}${TERMINAL_WIDTH}cols${C_RESET}"

# Línea 2: Métricas principales
if [ "$CCUSAGE_AVAILABLE" = true ]; then
    # Construir línea con datos disponibles
    LINE2="🤖 ${C_MODEL}${MODEL}${C_RESET}"
    
    # Sesión
    [ -n "$SESSION_FINAL" ] && LINE2="$LINE2 │ 💰 ${SESSION_COLOR}${SESSION_FINAL}${C_RESET}"
    
    # Hoy
    [ -n "$TODAY_COST" ] && LINE2="$LINE2 │ 📅 ${C_COST}${TODAY_COST}${C_RESET}"
    
    # Bloque
    if [ -n "$BLOCK_COST" ] && [ -n "$BLOCK_TIME" ]; then
        LINE2="$LINE2 │ ${TIME_EMOJI} ${BLOCK_COLOR}${BLOCK_COST} ${BLOCK_TIME}${C_RESET}"
    fi
    
    # Burn rate
    [ -n "$BURN_RATE" ] && LINE2="$LINE2 │ ${BURN_EMOJI} ${BURN_COLOR}${BURN_RATE}${C_RESET}"
    
    # Contexto
    [ -n "$CONTEXT_INFO" ] && LINE2="$LINE2 │ ${CTX_EMOJI} ${CTX_COLOR}${CONTEXT_INFO}${C_RESET}"
    
    echo -e "$LINE2"
else
    # Fallback simple
    echo -e "🤖 ${C_MODEL}${MODEL}${C_RESET} │ 💰 ${SESSION_COLOR}${SESSION_FINAL}${C_RESET} │ ${CTX_EMOJI} ${CTX_COLOR}${CONTEXT_INFO:-N/A}${C_RESET}"
fi

# Línea 3: Info adicional (solo si no hay ccusage)
if [ "$CCUSAGE_AVAILABLE" = false ] && [ -n "$DURATION_FMT" ]; then
    SESSION_SHORT=$(echo "$SESSION_ID" | cut -c1-8)
    echo -e "${C_COUNT}${DURATION_FMT}${C_RESET} ${C_SESSION}${SESSION_SHORT}${C_RESET}"
fi