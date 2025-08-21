#!/bin/bash
set -euo pipefail

# Claude Code Config Restore Script  
# Restaura configuración en nueva máquina

# Auto-detectar rutas primero para logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="$REPO_DIR/logs/restore.log"

# Crear directorio de logs
mkdir -p "$REPO_DIR/logs" 2>/dev/null || true

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones de logging con archivo de log
log_info() {
    local msg="$1"
    echo -e "${BLUE}ℹ️  $msg${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $msg" >> "$LOG_FILE"
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}✅ $msg${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: $msg" >> "$LOG_FILE"
}

log_warning() {
    local msg="$1"
    echo -e "${YELLOW}⚠️  $msg${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $msg" >> "$LOG_FILE"
}

log_error() {
    local msg="$1"
    echo -e "${RED}❌ $msg${NC}" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $msg" >> "$LOG_FILE"
}

# Completar variables con logging
CLAUDE_DIR="$HOME/.claude"
CONFIG_DIR="$REPO_DIR/claude_config"

log_info "=== INICIO DE RESTAURACIÓN ==="
log_info "Timestamp: $(date)"
log_info "Script ejecutado desde: $SCRIPT_DIR"
log_info "Repositorio: $REPO_DIR"
log_info "Destino Claude: $CLAUDE_DIR"
log_info "Configuración fuente: $CONFIG_DIR"
log_info "Log file: $LOG_FILE"

echo -e "${BLUE}🔄 Restaurando configuración Claude Code...${NC}"
log_info "Usuario actual: $(whoami)"
log_info "Directorio home: $HOME"
log_info "PATH actual: $PATH"

# Validaciones iniciales con logging detallado
log_info "=== VALIDACIONES INICIALES ==="

log_info "Verificando directorio de configuración..."
if [ ! -d "$CONFIG_DIR" ]; then
    log_error "Directorio de configuración no encontrado: $CONFIG_DIR"
    log_error "Asegúrate de ejecutar desde el repositorio claude-code-config"
    log_error "Contenido del directorio repo: $(ls -la "$REPO_DIR" 2>/dev/null || echo 'no accesible')"
    exit 1
fi
log_info "✓ Directorio de configuración existe"
log_info "Contenido de $CONFIG_DIR: $(ls -la "$CONFIG_DIR" 2>/dev/null | wc -l) elementos"

log_info "Verificando repositorio git..."
if [ ! -d "$REPO_DIR/.git" ]; then
    log_error "No parece ser un repositorio git: $REPO_DIR"
    log_error "Contenido del directorio: $(ls -la "$REPO_DIR" 2>/dev/null || echo 'no accesible')"
    exit 1
fi
log_info "✓ Repositorio git válido"

# Información adicional del repositorio
current_branch=$(git -C "$REPO_DIR" branch --show-current 2>/dev/null || echo "unknown")
log_info "Branch actual: $current_branch"
last_commit=$(git -C "$REPO_DIR" log -1 --oneline 2>/dev/null || echo "unknown")
log_info "Último commit: $last_commit"

# Verificar dependencias
log_info "Verificando dependencias del sistema..."
if ! command -v python3 >/dev/null 2>&1; then
    log_error "python3 no encontrado. Se requiere para procesar archivos JSON."
    exit 1
fi
python_version=$(python3 --version 2>&1 || echo "unknown")
log_info "✓ Python3 disponible: $python_version"

# Verificar módulos Python necesarios
log_info "Verificando módulos Python..."
if python3 -c "import json" 2>/dev/null; then
    log_info "✓ Módulo json disponible"
else
    log_error "Módulo json de Python no disponible"
    exit 1
fi

log_info "=== CONFIGURACIÓN VALIDADA ==="

# Crear directorio ~/.claude con validación y logging
log_info "=== PREPARACIÓN DEL ENTORNO ==="
log_info "Creando directorio de configuración Claude..."

# Verificar si el directorio ya existe
if [ -d "$CLAUDE_DIR" ]; then
    log_info "Directorio $CLAUDE_DIR ya existe"
    existing_files=$(ls -la "$CLAUDE_DIR" 2>/dev/null | wc -l)
    log_info "Archivos existentes en Claude dir: $((existing_files - 2))"  # -2 para . y ..
else
    log_info "Directorio $CLAUDE_DIR no existe, creando..."
fi

if ! mkdir -p "$CLAUDE_DIR" 2>/dev/null; then
    log_error "No se pudo crear el directorio: $CLAUDE_DIR"
    log_error "Permisos del directorio home: $(ls -ld "$HOME" 2>/dev/null || echo 'no accesible')"
    log_error "Verifica permisos de escritura en tu directorio home"
    exit 1
fi
log_info "✓ Directorio Claude creado/verificado"

# Verificar permisos del directorio creado
dir_permissions=$(ls -ld "$CLAUDE_DIR" 2>/dev/null || echo "no accesible")
log_info "Permisos del directorio Claude: $dir_permissions"

# Cambiar al directorio del repositorio
log_info "Cambiando al directorio del repositorio..."
original_pwd="$PWD"
log_info "Directorio actual: $original_pwd"

if ! cd "$REPO_DIR" 2>/dev/null; then
    log_error "No se pudo acceder al directorio del repositorio: $REPO_DIR"
    log_error "Permisos del directorio: $(ls -ld "$REPO_DIR" 2>/dev/null || echo 'no accesible')"
    exit 1
fi
log_info "✓ Cambio al directorio del repositorio exitoso"
log_info "Nuevo directorio de trabajo: $PWD"

# Función para restaurar archivos con validación y logging completo
restore_file() {
    local src="$1"
    local dst="$2" 
    local name="$3"
    
    log_info "Procesando archivo: $name"
    log_info "  Fuente: $src"
    log_info "  Destino: $dst"
    
    if [ -f "$src" ]; then
        if [ -r "$src" ]; then
            # Obtener información del archivo fuente
            src_size=$(stat -c%s "$src" 2>/dev/null || echo "unknown")
            src_perms=$(ls -l "$src" 2>/dev/null || echo "unknown")
            log_info "  Tamaño fuente: $src_size bytes"
            log_info "  Permisos fuente: $src_perms"
            
            # Verificar si el archivo destino ya existe
            if [ -f "$dst" ]; then
                dst_size=$(stat -c%s "$dst" 2>/dev/null || echo "unknown")
                log_info "  Archivo destino ya existe (tamaño: $dst_size bytes)"
                backup_file="${dst}.backup"
                if [ ! -f "$backup_file" ]; then
                    log_info "  Creando backup del archivo existente..."
                    if cp "$dst" "$backup_file" 2>/dev/null; then
                        log_info "  Backup creado: $backup_file"
                    else
                        log_warning "  No se pudo crear backup de $dst"
                    fi
                else
                    log_info "  Backup ya existe, omitiendo creación: $backup_file"
                fi
            fi
            
            # Intentar la copia
            if cp "$src" "$dst" 2>/dev/null; then
                # Verificar que la copia fue exitosa
                if [ -f "$dst" ]; then
                    new_size=$(stat -c%s "$dst" 2>/dev/null || echo "unknown")
                    log_success "$name restaurado exitosamente"
                    log_info "  Tamaño final: $new_size bytes"
                    
                    # Verificar integridad comparando tamaños
                    if [ "$src_size" = "$new_size" ]; then
                        log_info "  ✓ Integridad verificada (tamaños coinciden)"
                    else
                        log_warning "  Tamaños no coinciden: $src_size vs $new_size"
                    fi
                    return 0
                else
                    log_error "  Archivo no fue creado correctamente en destino"
                    return 1
                fi
            else
                log_error "Error copiando $name (operación de copia falló)"
                return 1
            fi
        else
            log_error "$name no se puede leer (permisos insuficientes)"
            log_error "  Permisos del archivo: $(ls -l "$src" 2>/dev/null || echo 'no accesible')"
            return 1
        fi
    else
        log_info "$name no encontrado en configuración, omitiendo"
        return 0
    fi
}

# Función para restaurar directorios con logging completo
restore_directory() {
    local src="$1"
    local dst_parent="$2"
    local name="$3"
    local dst_full="$dst_parent/$(basename "$src")"
    
    log_info "Procesando directorio: $name"
    log_info "  Fuente: $src"
    log_info "  Destino: $dst_full"
    
    if [ -d "$src" ]; then
        if [ -r "$src" ]; then
            # Contar archivos en el directorio fuente
            local src_files=$(find "$src" -type f 2>/dev/null | wc -l)
            local src_dirs=$(find "$src" -type d 2>/dev/null | wc -l)
            log_info "  Contenido fuente: $src_files archivos, $src_dirs directorios"
            
            # Verificar si el directorio destino ya existe
            if [ -d "$dst_full" ]; then
                local existing_files=$(find "$dst_full" -type f 2>/dev/null | wc -l)
                log_info "  Directorio destino ya existe ($existing_files archivos)"
                log_info "  Creando backup del directorio existente..."
                
                backup_dir="${dst_full}.backup"
                if mv "$dst_full" "$backup_dir" 2>/dev/null; then
                    log_info "  Backup creado: $backup_dir"
                else
                    log_warning "  No se pudo crear backup, eliminando directorio existente..."
                    if rm -rf "$dst_full" 2>/dev/null; then
                        log_info "  Directorio existente eliminado"
                    else
                        log_error "  No se pudo eliminar directorio existente"
                        return 1
                    fi
                fi
            fi
            
            # Intentar la copia recursiva
            log_info "  Iniciando copia recursiva..."
            if cp -r "$src" "$dst_parent/" 2>/dev/null; then
                # Verificar que la copia fue exitosa
                if [ -d "$dst_full" ]; then
                    local dst_files=$(find "$dst_full" -type f 2>/dev/null | wc -l)
                    local dst_dirs=$(find "$dst_full" -type d 2>/dev/null | wc -l)
                    log_success "$name restaurado exitosamente"
                    log_info "  Contenido final: $dst_files archivos, $dst_dirs directorios"
                    
                    # Verificar integridad comparando conteos
                    if [ "$src_files" -eq "$dst_files" ]; then
                        log_info "  ✓ Integridad verificada (conteos de archivos coinciden)"
                    else
                        log_warning "  Conteos no coinciden: $src_files vs $dst_files archivos"
                    fi
                    
                    # Establecer permisos
                    log_info "  Estableciendo permisos..."
                    chmod -R u+rw "$dst_full" 2>/dev/null || log_warning "No se pudieron ajustar todos los permisos"
                    
                    return 0
                else
                    log_error "  Directorio no fue creado correctamente en destino"
                    return 1
                fi
            else
                log_error "Error copiando directorio $name (operación de copia falló)"
                return 1
            fi
        else
            log_error "$name no se puede leer (permisos insuficientes)"
            log_error "  Permisos del directorio: $(ls -ld "$src" 2>/dev/null || echo 'no accesible')"
            return 1
        fi
    else
        log_info "$name no encontrado en configuración, omitiendo"
        return 0
    fi
}

# Restaurar archivos principales con logging detallado
log_info "=== RESTAURACIÓN DE ARCHIVOS PRINCIPALES ==="

# Listar archivos disponibles para restaurar
available_files=$(ls -la "$CONFIG_DIR" 2>/dev/null | grep '^-' | wc -l)
log_info "Archivos disponibles para restaurar: $available_files"
log_info "Contenido del directorio de configuración:"
ls -la "$CONFIG_DIR" 2>/dev/null | head -20 >> "$LOG_FILE"

files_restored=0
files_failed=0

log_info "Iniciando restauración de archivos individuales..."

if restore_file "$CONFIG_DIR/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"; then
    ((files_restored++))
else
    ((files_failed++))
fi

if restore_file "$CONFIG_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md"; then
    ((files_restored++))
else
    ((files_failed++))
fi

if restore_file "$CONFIG_DIR/CLAUDE_CODE_REFERENCE.md" "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md" "CLAUDE_CODE_REFERENCE.md"; then
    ((files_restored++))
else
    ((files_failed++))
fi

log_info "Resultado archivos principales: $files_restored restaurados, $files_failed fallidos"

# Restaurar directorios opcionales con logging detallado
log_info "=== RESTAURACIÓN DE DIRECTORIOS PERSONALIZADOS ==="

dirs_restored=0
dirs_failed=0

log_info "Verificando directorios disponibles..."
available_dirs=$(ls -la "$CONFIG_DIR" 2>/dev/null | grep '^d' | grep -v '\.$' | wc -l)
log_info "Directorios disponibles: $available_dirs"

if restore_directory "$CONFIG_DIR/commands" "$CLAUDE_DIR" "comandos personalizados"; then
    ((dirs_restored++))
else
    ((dirs_failed++))
fi

if restore_directory "$CONFIG_DIR/agents" "$CLAUDE_DIR" "agentes personalizados"; then
    ((dirs_restored++))
else
    ((dirs_failed++))
fi

log_info "Resultado directorios: $dirs_restored restaurados, $dirs_failed fallidos"

# Merge inteligente de ~/.claude.json con logging extensivo
log_info "=== PROCESAMIENTO DE CONFIGURACIÓN INTERNA ==="
log_info "Iniciando merge inteligente de ~/.claude.json..."

if [ -f "$CONFIG_DIR/.claude.json" ]; then
    config_file_size=$(stat -c%s "$CONFIG_DIR/.claude.json" 2>/dev/null || echo "unknown")
    log_info "Archivo de configuración encontrado (tamaño: $config_file_size bytes)"
    
    # Validar que el archivo de configuración es JSON válido
    log_info "Validando formato JSON del archivo de configuración..."
    if ! python3 -c "import json; json.load(open('$CONFIG_DIR/.claude.json'))" 2>/dev/null; then
        log_error "El archivo .claude.json en la configuración no es JSON válido"
        log_error "Mostrando primeras líneas del archivo problemático:"
        head -10 "$CONFIG_DIR/.claude.json" 2>/dev/null | while read line; do
            log_error "  $line"
        done
        log_warning "Omitiendo restauración de configuración interna"
    else
        log_info "✓ Archivo de configuración es JSON válido"
        if [ -f "$HOME/.claude.json" ]; then
            # Archivo existe, hacer merge inteligente
            existing_file_size=$(stat -c%s "$HOME/.claude.json" 2>/dev/null || echo "unknown")
            log_info "Archivo ~/.claude.json existe (tamaño: $existing_file_size bytes)"
            log_info "Procediendo con merge inteligente..."
            
            # Crear backup único
            backup_file="$HOME/.claude.json.backup"
            if [ ! -f "$backup_file" ]; then
                log_info "Creando backup en: $backup_file"
                if cp "$HOME/.claude.json" "$backup_file" 2>/dev/null; then
                    backup_size=$(stat -c%s "$backup_file" 2>/dev/null || echo "unknown")
                    log_success "Backup creado exitosamente (tamaño: $backup_size bytes)"
                else
                    log_error "No se pudo crear backup del archivo existente"
                    log_error "Permisos del archivo: $(ls -l "$HOME/.claude.json" 2>/dev/null || echo 'no accesible')"
                    exit 1
                fi
            else
                log_info "Backup ya existe, omitiendo creación: $backup_file"
            fi
            
            # Validar que el archivo existente es JSON válido
            log_info "Validando formato JSON del archivo existente..."
            if ! python3 -c "import json; json.load(open('$HOME/.claude.json'))" 2>/dev/null; then
                log_error "El archivo ~/.claude.json existente no es JSON válido"
                log_error "Mostrando primeras líneas del archivo problemático:"
                head -10 "$HOME/.claude.json" 2>/dev/null | while read line; do
                    log_error "  $line"
                done
                log_info "Reemplazando con configuración desde el repositorio..."
                if cp "$CONFIG_DIR/.claude.json" "$HOME/.claude.json" 2>/dev/null; then
                    new_size=$(stat -c%s "$HOME/.claude.json" 2>/dev/null || echo "unknown")
                    log_success "Archivo ~/.claude.json reemplazado (nuevo tamaño: $new_size bytes)"
                else
                    log_error "Error reemplazando el archivo"
                    exit 1
                fi
            else
                log_info "✓ Archivo existente es JSON válido"
                # Hacer merge usando Python con logging detallado
                log_info "Iniciando proceso de merge con Python..."
                
                # Primero analizar contenido antes del merge
                config_servers=$(python3 -c "
try:
    import json
    with open('$CONFIG_DIR/.claude.json', 'r') as f:
        data = json.load(f)
    if 'mcpServers' in data:
        print(len(data['mcpServers']))
    else:
        print(0)
except: print('error')
" 2>/dev/null || echo "unknown")
                
                existing_servers=$(python3 -c "
try:
    import json
    with open('$HOME/.claude.json', 'r') as f:
        data = json.load(f)
    if 'mcpServers' in data:
        print(len(data['mcpServers']))
    else:
        print(0)
except: print('error')
" 2>/dev/null || echo "unknown")
                
                log_info "MCP Servers en config: $config_servers"
                log_info "MCP Servers existentes: $existing_servers"
                
                merge_result=$(python3 -c "
import json
import sys

try:
    # Leer archivo de configuración
    with open('$CONFIG_DIR/.claude.json', 'r') as f:
        config_data = json.load(f)
    
    # Leer archivo actual del usuario
    with open('$HOME/.claude.json', 'r') as f:
        user_data = json.load(f)
    
    # Solo reemplazar la sección mcpServers si existe en config
    merged = False
    if 'mcpServers' in config_data:
        user_data['mcpServers'] = config_data['mcpServers']
        merged = True
        
        # Escribir archivo actualizado
        with open('$HOME/.claude.json', 'w') as f:
            json.dump(user_data, f, indent=2)
    
    if merged:
        print('success')
    else:
        print('no_mcpservers')
        
except Exception as e:
    print(f'error: {e}')
    sys.exit(1)
" 2>&1)
                
                log_info "Resultado del script de merge: $merge_result"

                case "$merge_result" in
                    "success")
                        # Verificar el resultado del merge
                        final_size=$(stat -c%s "$HOME/.claude.json" 2>/dev/null || echo "unknown")
                        final_servers=$(python3 -c "
try:
    import json
    with open('$HOME/.claude.json', 'r') as f:
        data = json.load(f)
    if 'mcpServers' in data:
        print(len(data['mcpServers']))
    else:
        print(0)
except: print('error')
" 2>/dev/null || echo "unknown")
                        
                        log_success "MCP Servers fusionados exitosamente"
                        log_info "  Archivo final: $final_size bytes"
                        log_info "  MCP Servers finales: $final_servers"
                        log_info "  Resto del archivo preservado"
                        ;;
                    "no_mcpservers")
                        log_warning "No se encontró sección mcpServers en configuración"
                        log_info "Archivo de usuario permanece sin cambios"
                        ;;
                    error:*)
                        log_error "Error durante el merge: ${merge_result#error: }"
                        log_info "Restaurando desde backup: $backup_file"
                        if cp "$backup_file" "$HOME/.claude.json" 2>/dev/null; then
                            restored_size=$(stat -c%s "$HOME/.claude.json" 2>/dev/null || echo "unknown")
                            log_info "Backup restaurado (tamaño: $restored_size bytes)"
                        else
                            log_error "Error restaurando backup"
                        fi
                        exit 1
                        ;;
                esac
            fi
        else
            # Archivo no existe, copiar completo
            log_info "Archivo ~/.claude.json no existe, copiando configuración completa..."
            log_info "Fuente: $CONFIG_DIR/.claude.json (tamaño: $config_file_size bytes)"
            
            if cp "$CONFIG_DIR/.claude.json" "$HOME/.claude.json" 2>/dev/null; then
                copied_size=$(stat -c%s "$HOME/.claude.json" 2>/dev/null || echo "unknown")
                copied_servers=$(python3 -c "
try:
    import json
    with open('$HOME/.claude.json', 'r') as f:
        data = json.load(f)
    if 'mcpServers' in data:
        print(len(data['mcpServers']))
    else:
        print(0)
except: print('error')
" 2>/dev/null || echo "unknown")
                
                log_success "Configuración interna restaurada completamente"
                log_info "  Archivo creado: $copied_size bytes"
                log_info "  MCP Servers incluidos: $copied_servers"
                
                # Establecer permisos apropiados
                chmod 600 "$HOME/.claude.json" 2>/dev/null || log_warning "No se pudieron ajustar permisos del archivo"
                final_perms=$(ls -l "$HOME/.claude.json" 2>/dev/null || echo "no accesible")
                log_info "  Permisos finales: $final_perms"
            else
                log_error "Error copiando configuración interna"
                log_error "Permisos directorio destino: $(ls -ld "$HOME" 2>/dev/null || echo 'no accesible')"
                exit 1
            fi
        fi
    fi
else
    log_warning "Archivo .claude.json no encontrado en configuración"
    log_info "Listado del directorio de configuración:"
    ls -la "$CONFIG_DIR" 2>/dev/null | while read line; do
        log_info "  $line"
    done
    log_info "La configuración interna se creará automáticamente cuando ejecutes Claude Code"
fi

# Verificar permisos finales con logging detallado
log_info "=== VERIFICACIÓN Y AJUSTE DE PERMISOS ==="

if [ -d "$CLAUDE_DIR" ]; then
    log_info "Ajustando permisos del directorio Claude..."
    
    # Permisos del directorio principal
    log_info "Estableciendo permisos 755 para directorio principal..."
    if chmod 755 "$CLAUDE_DIR" 2>/dev/null; then
        log_info "✓ Permisos del directorio principal ajustados"
    else
        log_warning "No se pudieron ajustar permisos del directorio principal"
    fi
    
    # Permisos de archivos
    file_count=$(find "$CLAUDE_DIR" -type f 2>/dev/null | wc -l)
    log_info "Estableciendo permisos 644 para $file_count archivos..."
    if find "$CLAUDE_DIR" -type f -exec chmod 644 {} \; 2>/dev/null; then
        log_info "✓ Permisos de archivos ajustados"
    else
        log_warning "No se pudieron ajustar permisos de todos los archivos"
    fi
    
    # Permisos de subdirectorios
    dir_count=$(find "$CLAUDE_DIR" -type d 2>/dev/null | wc -l)
    log_info "Estableciendo permisos 755 para $dir_count directorios..."
    if find "$CLAUDE_DIR" -type d -exec chmod 755 {} \; 2>/dev/null; then
        log_info "✓ Permisos de directorios ajustados"
    else
        log_warning "No se pudieron ajustar permisos de todos los directorios"
    fi
    
    # Permisos especiales para archivo sensible
    if [ -f "$HOME/.claude.json" ]; then
        log_info "Estableciendo permisos restrictivos para .claude.json..."
        if chmod 600 "$HOME/.claude.json" 2>/dev/null; then
            log_info "✓ Permisos restrictivos aplicados a .claude.json"
        else
            log_warning "No se pudieron establecer permisos restrictivos para .claude.json"
        fi
    fi
    
    log_success "Proceso de ajuste de permisos completado"
    
    # Mostrar resumen de permisos finales
    log_info "Resumen de permisos finales:"
    log_info "  Directorio principal: $(ls -ld "$CLAUDE_DIR" 2>/dev/null | awk '{print $1}' || echo 'no accesible')"
    if [ -f "$HOME/.claude.json" ]; then
        log_info "  Archivo .claude.json: $(ls -l "$HOME/.claude.json" 2>/dev/null | awk '{print $1}' || echo 'no accesible')"
    fi
else
    log_error "Directorio Claude no existe después de la restauración"
fi

echo ""
log_success "¡Configuración restaurada correctamente!"

# Estadísticas finales
log_info "=== ESTADÍSTICAS FINALES DE RESTAURACIÓN ==="
log_info "Timestamp de finalización: $(date)"
log_info "Duración total: $SECONDS segundos"
log_info "Archivos procesados: $((files_restored + files_failed))"
log_info "Directorios procesados: $((dirs_restored + dirs_failed))"
log_info "Éxitos totales: $((files_restored + dirs_restored))"
log_info "Fallos totales: $((files_failed + dirs_failed))"

# Estado final del directorio Claude
if [ -d "$CLAUDE_DIR" ]; then
    total_files=$(find "$CLAUDE_DIR" -type f 2>/dev/null | wc -l)
    total_dirs=$(find "$CLAUDE_DIR" -type d 2>/dev/null | wc -l)
    total_size=$(du -sh "$CLAUDE_DIR" 2>/dev/null | cut -f1 || echo "unknown")
    log_info "Estado final del directorio Claude:"
    log_info "  Total archivos: $total_files"
    log_info "  Total directorios: $total_dirs"
    log_info "  Tamaño total: $total_size"
fi

echo ""

# Mostrar resumen detallado de lo que se restauró
log_info "=== RESUMEN DETALLADO DE ARCHIVOS RESTAURADOS ==="

restored_items=0

if [ -f "$CLAUDE_DIR/settings.json" ]; then
    size=$(stat -c%s "$CLAUDE_DIR/settings.json" 2>/dev/null || echo "unknown")
    echo "  ✅ settings.json ($size bytes)"
    log_info "settings.json restaurado: $size bytes"
    ((restored_items++))
fi

if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    size=$(stat -c%s "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null || echo "unknown")
    echo "  ✅ CLAUDE.md ($size bytes)"
    log_info "CLAUDE.md restaurado: $size bytes"
    ((restored_items++))
fi

if [ -f "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md" ]; then
    size=$(stat -c%s "$CLAUDE_DIR/CLAUDE_CODE_REFERENCE.md" 2>/dev/null || echo "unknown")
    echo "  ✅ CLAUDE_CODE_REFERENCE.md ($size bytes)"
    log_info "CLAUDE_CODE_REFERENCE.md restaurado: $size bytes"
    ((restored_items++))
fi

if [ -f "$HOME/.claude.json" ]; then
    size=$(stat -c%s "$HOME/.claude.json" 2>/dev/null || echo "unknown")
    servers=$(python3 -c "try:
    import json
    with open('$HOME/.claude.json', 'r') as f:
        data = json.load(f)
    print(len(data.get('mcpServers', {})))
except: print('error')" 2>/dev/null || echo "unknown")
    echo "  ✅ .claude.json ($size bytes, $servers MCP servers)"
    log_info ".claude.json restaurado: $size bytes, $servers MCP servers"
    ((restored_items++))
fi

if [ -d "$CLAUDE_DIR/commands" ]; then
    count=$(find "$CLAUDE_DIR/commands" -type f 2>/dev/null | wc -l)
    size=$(du -sh "$CLAUDE_DIR/commands" 2>/dev/null | cut -f1 || echo "unknown")
    echo "  ✅ commands/ ($count archivos, $size total)"
    log_info "commands/ restaurado: $count archivos, $size total"
    ((restored_items++))
fi

if [ -d "$CLAUDE_DIR/agents" ]; then
    count=$(find "$CLAUDE_DIR/agents" -type f 2>/dev/null | wc -l)
    size=$(du -sh "$CLAUDE_DIR/agents" 2>/dev/null | cut -f1 || echo "unknown")
    echo "  ✅ agents/ ($count archivos, $size total)"
    log_info "agents/ restaurado: $count archivos, $size total"
    ((restored_items++))
fi

log_info "Total de elementos restaurados: $restored_items"

echo ""
echo -e "${BLUE}📋 Próximos pasos:${NC}"
echo "  1. Ejecutar './scripts/install-service.sh' para activar sincronización automática"
echo "  2. Ejecutar 'claude' para inicializar Claude Code si es necesario"
echo "  3. Verificar que los MCP servers están funcionando correctamente"
echo "  4. Revisar log de restauración: $LOG_FILE"
echo ""
log_info "La configuración estará lista para usar con Claude Code"
log_info "=== RESTAURACIÓN COMPLETADA EXITOSAMENTE $(date) ==="

# Información final del log
if [ -f "$LOG_FILE" ]; then
    log_size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo "0")
    log_lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
    log_info "Log de restauración: $log_lines líneas, $log_size bytes"
    log_info "Para revisar el log completo: cat $LOG_FILE"
fi