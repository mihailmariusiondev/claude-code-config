#!/bin/bash
set -euo pipefail

# Claude Code Config - Service Installer
# Instala o reinstala el servicio systemd

# Auto-detectar rutas primero para logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$REPO_DIR/logs/install-service.log"

# Crear directorio de logs
mkdir -p "$REPO_DIR/logs" 2>/dev/null || true

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging con colores Y archivo de log
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

echo -e "${BLUE}🔧 Instalando servicio claude-sync...${NC}"
log_info "=== Inicio de instalación del servicio claude-sync ==="nlog_info "Script ejecutado desde: $SCRIPT_DIR"
log_info "Repositorio: $REPO_DIR"
log_info "Log file: $LOG_FILE"

# Validaciones iniciales con logging completo
log_info "Iniciando validaciones del sistema..."
if [[ $EUID -eq 0 ]]; then
    log_error "Este script no debe ejecutarse como root. Usar sudo solo cuando sea necesario."
    exit 1
fi
log_info "✓ Usuario no es root: $(whoami)"

if ! command -v systemctl >/dev/null 2>&1; then
    log_error "systemctl no encontrado. Este script requiere systemd."
    exit 1
fi
log_info "✓ systemctl encontrado: $(command -v systemctl)"

if ! command -v sudo >/dev/null 2>&1; then
    log_error "sudo no encontrado. Se requiere para instalar servicios systemd."
    exit 1
fi
log_info "✓ sudo encontrado: $(command -v sudo)"

# Completar variables con logging
CURRENT_USER="$(whoami)"
SERVICE_FILE="/etc/systemd/system/claude-sync.service"
SYNC_SCRIPT="$REPO_DIR/scripts/sync.sh"

log_info "Variables de configuración:"
log_info "  - Usuario actual: $CURRENT_USER"
log_info "  - Archivo de servicio: $SERVICE_FILE"
log_info "  - Script de sync: $SYNC_SCRIPT"

# Validar estructura del repositorio con logging detallado
log_info "Validando estructura del repositorio..."

log_info "Verificando existencia de sync.sh..."
if [ ! -f "$SYNC_SCRIPT" ]; then
    log_error "Script sync.sh no encontrado en: $SYNC_SCRIPT"
    log_error "Contenido del directorio scripts: $(ls -la "$REPO_DIR/scripts/" 2>/dev/null || echo 'directorio no existe')"
    exit 1
fi
log_info "✓ sync.sh encontrado"

log_info "Verificando permisos de ejecución..."
if [ ! -x "$SYNC_SCRIPT" ]; then
    log_warning "Script sync.sh no es ejecutable, añadiendo permisos..."
    log_info "Permisos actuales: $(ls -l "$SYNC_SCRIPT")"
    if chmod +x "$SYNC_SCRIPT" 2>/dev/null; then
        log_success "Permisos de ejecución añadidos"
        log_info "Nuevos permisos: $(ls -l "$SYNC_SCRIPT")"
    else
        log_error "No se pudieron establecer permisos de ejecución en sync.sh"
        exit 1
    fi
else
    log_info "✓ sync.sh ya es ejecutable"
fi

log_info "Verificando repositorio git..."
if [ ! -d "$REPO_DIR/.git" ]; then
    log_error "El directorio $REPO_DIR no parece ser un repositorio git"
    log_error "Contenido del directorio: $(ls -la "$REPO_DIR/" 2>/dev/null || echo 'directorio no accesible')"
    exit 1
fi
log_info "✓ Repositorio git válido"

# Verificar branch actual
current_branch=$(git -C "$REPO_DIR" branch --show-current 2>/dev/null || echo "unknown")
log_info "Branch actual: $current_branch"

log_info "=== Configuración validada correctamente ==="

# Verificar estado actual del servicio con logging detallado
log_info "Verificando estado actual del servicio..."

if systemctl is-active --quiet claude-sync.service; then
    log_warning "Servicio claude-sync ya está corriendo, deteniéndolo..."
    log_info "Estado antes de detener: $(systemctl is-active claude-sync.service 2>/dev/null || echo 'inactive')"
    if sudo systemctl stop claude-sync.service 2>/dev/null; then
        log_success "Servicio detenido correctamente"
    else
        log_error "Error deteniendo el servicio existente"
        exit 1
    fi
else
    log_info "✓ Servicio no está corriendo actualmente"
fi

if systemctl is-enabled --quiet claude-sync.service 2>/dev/null; then
    log_info "Servicio claude-sync ya está habilitado, será reconfigurado"
    log_info "Estado de habilitación: $(systemctl is-enabled claude-sync.service 2>/dev/null || echo 'disabled')"
else
    log_info "✓ Servicio no está habilitado previamente"
fi

# Crear archivo de servicio con validaciones y logging completo
log_info "Preparando creación del archivo de servicio systemd..."

# Validar que tenemos permisos de sudo
log_info "Verificando permisos de sudo..."
if ! sudo -n true 2>/dev/null; then
    log_warning "Se requieren permisos de administrador para instalar el servicio"
    log_info "Solicitando contraseña de sudo..."
    echo "Por favor ingresa tu contraseña cuando se solicite:"
else
    log_info "✓ Permisos de sudo ya disponibles (sin contraseña)"
fi

# Log del contenido del servicio que se va a crear
log_info "Contenido del archivo de servicio a crear:"
log_info "  User: $CURRENT_USER"
log_info "  WorkingDirectory: $REPO_DIR"
log_info "  ExecStart: $SYNC_SCRIPT"
log_info "  ReadWritePaths: $REPO_DIR $HOME/.claude $HOME/.claude.json"

# Crear el archivo de servicio con validación y logging
log_info "Creando archivo $SERVICE_FILE..."
if sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=Claude Code Config Auto-Sync Service
Documentation=https://github.com/user/claude-code-config
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_USER
WorkingDirectory=$REPO_DIR
ExecStart=$SYNC_SCRIPT
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
TimeoutStopSec=30

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=claude-sync

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$REPO_DIR $HOME/.claude $HOME/.claude.json
ProtectHome=read-only

# Environment
Environment=PATH=/usr/local/bin:/usr/bin:/bin
Environment=HOME=$HOME

[Install]
WantedBy=multi-user.target
EOF
then
    log_success "Archivo de servicio creado: $SERVICE_FILE"
    log_info "Verificando contenido del archivo creado..."
    if [ -f "$SERVICE_FILE" ]; then
        service_size=$(stat -c%s "$SERVICE_FILE" 2>/dev/null || echo "0")
        log_info "Tamaño del archivo de servicio: $service_size bytes"
        log_info "Permisos del archivo: $(ls -l "$SERVICE_FILE" 2>/dev/null || echo 'no accesible')"
    fi
else
    log_error "Error creando el archivo de servicio"
    log_error "Verificando directorio /etc/systemd/system/: $(ls -la /etc/systemd/system/ | grep claude 2>/dev/null || echo 'no hay archivos claude')"
    exit 1
fi

# Validar que el archivo fue creado correctamente con logging detallado
log_info "Validando creación del archivo de servicio..."
if [ ! -f "$SERVICE_FILE" ]; then
    log_error "El archivo de servicio no fue creado correctamente"
    log_error "Listado de /etc/systemd/system/: $(ls -la /etc/systemd/system/ | tail -5)"
    exit 1
fi
log_info "✓ Archivo de servicio existe y es accesible"

# Validar contenido del archivo
log_info "Validando contenido del archivo de servicio..."
if grep -q "$CURRENT_USER" "$SERVICE_FILE" 2>/dev/null; then
    log_info "✓ Usuario correcto en el archivo de servicio"
else
    log_error "Usuario no encontrado en el archivo de servicio"
    exit 1
fi

if grep -q "$REPO_DIR" "$SERVICE_FILE" 2>/dev/null; then
    log_info "✓ Directorio de trabajo correcto en el archivo"
else
    log_error "Directorio de trabajo no encontrado en el archivo de servicio"
    exit 1
fi

# Recargar systemd con logging detallado
log_info "Recargando configuración de systemd..."
log_info "Ejecutando: sudo systemctl daemon-reload"
reload_output=$(sudo systemctl daemon-reload 2>&1)
reload_exit=$?
if [ $reload_exit -eq 0 ]; then
    log_success "Configuración de systemd recargada"
    log_info "Salida del comando: ${reload_output:-'sin salida'}"
else
    log_error "Error recargando systemd (código: $reload_exit)"
    log_error "Salida del error: $reload_output"
    exit 1
fi

# Habilitar servicio con logging detallado
log_info "Habilitando servicio claude-sync..."
log_info "Ejecutando: sudo systemctl enable claude-sync.service"
enable_output=$(sudo systemctl enable claude-sync.service 2>&1)
enable_exit=$?
if [ $enable_exit -eq 0 ]; then
    log_success "Servicio habilitado para inicio automático"
    log_info "Salida del comando: $enable_output"
    
    # Verificar que realmente está habilitado
    if systemctl is-enabled --quiet claude-sync.service; then
        log_info "✓ Confirmado: servicio está habilitado"
    else
        log_warning "Advertencia: el comando enable no falló pero el servicio no aparece habilitado"
    fi
else
    log_error "Error habilitando el servicio (código: $enable_exit)"
    log_error "Salida del error: $enable_output"
    exit 1
fi

# Iniciar servicio con logging detallado
log_info "Iniciando servicio claude-sync..."
log_info "Ejecutando: sudo systemctl start claude-sync.service"
start_output=$(sudo systemctl start claude-sync.service 2>&1)
start_exit=$?
if [ $start_exit -eq 0 ]; then
    log_success "Servicio iniciado correctamente"
    log_info "Salida del comando: ${start_output:-'sin salida'}"
else
    log_error "Error iniciando el servicio (código: $start_exit)"
    log_error "Salida del error: $start_output"
    
    # Mostrar logs de error para debugging
    echo ""
    log_error "Logs de error del servicio (últimas 20 líneas):"
    error_logs=$(sudo journalctl -u claude-sync.service -n 20 --no-pager 2>&1)
    log_error "$error_logs"
    exit 1
fi

# Verificar que el servicio está corriendo con logging detallado
log_info "Esperando 2 segundos para verificación del estado..."
sleep 2

log_info "Verificando estado final del servicio..."
service_status=$(systemctl is-active claude-sync.service 2>&1)
if systemctl is-active --quiet claude-sync.service; then
    log_success "Servicio claude-sync está corriendo correctamente"
    log_info "Estado del servicio: $service_status"
    
    # Información adicional del servicio
    service_pid=$(systemctl show claude-sync.service --property=MainPID --value 2>/dev/null || echo "unknown")
    log_info "PID del proceso principal: $service_pid"
    
    service_memory=$(systemctl show claude-sync.service --property=MemoryCurrent --value 2>/dev/null || echo "unknown")
    log_info "Memoria utilizada: $service_memory bytes"
else
    log_error "El servicio no pudo iniciarse correctamente"
    log_error "Estado reportado: $service_status"
    
    # Logs finales para debugging
    log_error "Logs finales del servicio:"
    final_logs=$(sudo journalctl -u claude-sync.service -n 10 --no-pager 2>&1)
    log_error "$final_logs"
    exit 1
fi

echo ""
log_success "Instalación completada exitosamente!"
log_info "=== RESUMEN FINAL DE LA INSTALACIÓN ==="
log_info "Fecha/hora: $(date)"
log_info "Usuario: $CURRENT_USER"
log_info "Repositorio: $REPO_DIR"
log_info "Archivo de servicio: $SERVICE_FILE"
log_info "Log de instalación: $LOG_FILE"

echo ""
echo -e "${BLUE}📊 Estado del servicio:${NC}"
status_output=$(sudo systemctl status claude-sync.service --no-pager -l 2>&1)
echo "$status_output"
log_info "Estado completo del servicio guardado en log"
echo "$status_output" >> "$LOG_FILE"

echo ""
echo -e "${BLUE}📋 Comandos útiles:${NC}"
echo "  • Ver estado:     sudo systemctl status claude-sync.service"
echo "  • Ver logs:       sudo journalctl -u claude-sync.service -f"
echo "  • Reiniciar:      sudo systemctl restart claude-sync.service"  
echo "  • Detener:        sudo systemctl stop claude-sync.service"
echo "  • Deshabilitar:   sudo systemctl disable claude-sync.service"
echo "  • Ver log instalación: cat $LOG_FILE"
echo ""
log_info "El servicio sincronizará automáticamente cada 1 minuto"
log_info "=== Instalación completada exitosamente a las $(date) ==="

# Verificación final de logs
if [ -f "$LOG_FILE" ]; then
    log_size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo "0")
    log_info "Tamaño final del log de instalación: $log_size bytes"
fi