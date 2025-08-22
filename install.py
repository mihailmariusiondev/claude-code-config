#!/usr/bin/env python3
"""
Claude Code Config - Script Único en Python
Restaura + Instala servicio + Sync automático
Version 4.0 - Python puro, cero bash complexity
"""

import os
import sys
import json
import time
import shutil
import subprocess
import logging
from pathlib import Path
from typing import Dict, Optional

#=============================================================================
# CONSTANTES GLOBALES
#=============================================================================
SCRIPT_VERSION = "4.0"
SYNC_INTERVAL = 60  # segundos
SERVICE_NAME = "claude-sync.service"
LOG_FORMAT = "%(asctime)s - %(levelname)s - %(message)s"

# Rutas dinámicas
SCRIPT_DIR = Path(__file__).parent.absolute()
REPO_DIR = SCRIPT_DIR
CONFIG_DIR = REPO_DIR / "claude_config"
LOGS_DIR = REPO_DIR / "logs"
SERVICE_FILE = Path("/etc/systemd/system") / SERVICE_NAME

# Detectar usuario y home real (cuando se ejecuta con sudo)
SUDO_USER = os.environ.get('SUDO_USER')
if SUDO_USER:
    import pwd
    USER_HOME = Path(pwd.getpwnam(SUDO_USER).pw_dir)
    CURRENT_USER = SUDO_USER
else:
    USER_HOME = Path.home()
    CURRENT_USER = os.getenv('USER', 'unknown')

CLAUDE_DIR = USER_HOME / ".claude"
CLAUDE_JSON = USER_HOME / ".claude.json"

# Archivos de configuración
CONFIG_FILES = {
    "settings.json": "settings.json",
    "CLAUDE.md": "CLAUDE.md", 
    "CLAUDE_CODE_REFERENCE.md": "CLAUDE_CODE_REFERENCE.md"
}

CONFIG_DIRS = ["commands", "agents"]

#=============================================================================
# SETUP LOGGING
#=============================================================================
def setup_logging(daemon_mode=False):
    """Configurar logging según el modo"""
    LOGS_DIR.mkdir(exist_ok=True)
    
    if daemon_mode:
        log_file = LOGS_DIR / "sync.log"
        logging.basicConfig(
            level=logging.INFO,
            format=LOG_FORMAT,
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
    else:
        logging.basicConfig(level=logging.INFO, format=LOG_FORMAT)

#=============================================================================
# VALIDACIONES
#=============================================================================
def validate_environment():
    """Validar entorno y dependencias"""
    # No root directo
    if os.geteuid() == 0 and not SUDO_USER:
        print("❌ No ejecutar como root directo. Usa: sudo ./install.py")
        sys.exit(1)
    
    # Verificar systemd
    if not shutil.which('systemctl'):
        print("❌ systemctl no encontrado. Se requiere systemd.")
        sys.exit(1)
        
    # Verificar git
    if not shutil.which('git'):
        print("❌ git no encontrado. Se requiere git.")
        sys.exit(1)

#=============================================================================
# PASO 1: RESTAURAR CONFIGURACIÓN
#=============================================================================
def restore_configuration():
    """Restaurar configuración ~/.claude/"""
    print(f"📁 PASO 1/3: Restaurando configuración {CLAUDE_DIR}")
    print(f"Fuente: {CONFIG_DIR}")
    print(f"Destino: {CLAUDE_DIR}")
    
    # Crear directorios
    CLAUDE_DIR.mkdir(parents=True, exist_ok=True)
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    
    # Copiar archivos principales
    for config_file, claude_file in CONFIG_FILES.items():
        src = CONFIG_DIR / config_file
        dst = CLAUDE_DIR / claude_file
        
        if src.exists():
            print(f"📄 Copiando {config_file}...")
            shutil.copy2(src, dst)
            print(f"✅ {config_file} copiado")
        else:
            print(f"⚠️ {config_file} no encontrado")
    
    # Copiar directorios
    for dir_name in CONFIG_DIRS:
        src_dir = CONFIG_DIR / dir_name
        dst_dir = CLAUDE_DIR / dir_name
        
        if src_dir.exists():
            print(f"📁 Copiando {dir_name}/")
            if dst_dir.exists():
                shutil.rmtree(dst_dir)
            shutil.copytree(src_dir, dst_dir)
            print(f"✅ {dir_name}/ copiado")
    
    # Procesar .claude.json con merge inteligente
    process_claude_json()
    
    print("✅ PASO 1 COMPLETADO: Configuración restaurada\n")

def process_claude_json():
    """Procesar .claude.json con merge inteligente de mcpServers"""
    config_json = CONFIG_DIR / ".claude.json"
    
    if not config_json.exists():
        return
        
    print("📋 Procesando .claude.json...")
    
    try:
        # Validar JSON
        with open(config_json) as f:
            config_data = json.load(f)
        
        if CLAUDE_JSON.exists():
            # Backup único
            backup_file = CLAUDE_JSON.with_suffix('.json.backup')
            if not backup_file.exists():
                shutil.copy2(CLAUDE_JSON, backup_file)
                print("✅ Backup creado")
            
            # Merge mcpServers
            with open(CLAUDE_JSON) as f:
                user_data = json.load(f)
            
            if 'mcpServers' in config_data:
                user_data['mcpServers'] = config_data['mcpServers']
                
                with open(CLAUDE_JSON, 'w') as f:
                    json.dump(user_data, f, indent=2)
                print("✅ MCP servers fusionados")
            else:
                print("⚠️ No hay mcpServers en config")
        else:
            # Copiar completo
            shutil.copy2(config_json, CLAUDE_JSON)
            CLAUDE_JSON.chmod(0o600)
            print("✅ .claude.json copiado")
            
    except json.JSONDecodeError:
        print("❌ .claude.json inválido")
    except Exception as e:
        print(f"❌ Error procesando JSON: {e}")

#=============================================================================
# PASO 2: INSTALAR SERVICIO SYSTEMD
#=============================================================================
def install_systemd_service():
    """Instalar servicio systemd"""
    print("⚙️ PASO 2/3: Instalando servicio claude-sync.service")
    
    # Detener servicio si existe
    try:
        result = subprocess.run(['systemctl', 'is-active', '--quiet', SERVICE_NAME], 
                              capture_output=True)
        if result.returncode == 0:
            print("🛑 Deteniendo servicio actual...")
            subprocess.run(['sudo', 'systemctl', 'stop', SERVICE_NAME], check=True)
    except subprocess.CalledProcessError:
        pass
    
    # Crear archivo de servicio
    print("📝 Creando archivo systemd...")
    service_content = f"""[Unit]
Description=Claude Code Config Auto-Sync Service  
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User={CURRENT_USER}
Group={CURRENT_USER}
WorkingDirectory={REPO_DIR}
ExecStart={sys.executable} {SCRIPT_DIR / 'install.py'} --daemon
Restart=always
RestartSec=10
TimeoutStopSec=30

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=claude-sync

# Security
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths={REPO_DIR} {CLAUDE_DIR} {CLAUDE_JSON}
ProtectHome=read-only

[Install]
WantedBy=multi-user.target
"""
    
    # Escribir archivo (requiere sudo)
    temp_service = SCRIPT_DIR / f"{SERVICE_NAME}.tmp"
    with open(temp_service, 'w') as f:
        f.write(service_content)
    
    subprocess.run(['sudo', 'cp', str(temp_service), str(SERVICE_FILE)], check=True)
    temp_service.unlink()
    
    # Recargar systemd
    print("🔄 Recargando systemd...")
    subprocess.run(['sudo', 'systemctl', 'daemon-reload'], check=True)
    
    # Habilitar e iniciar
    print("🚀 Habilitando e iniciando servicio...")
    subprocess.run(['sudo', 'systemctl', 'enable', SERVICE_NAME], check=True)
    subprocess.run(['sudo', 'systemctl', 'start', SERVICE_NAME], check=True)
    
    # Verificar
    time.sleep(2)
    result = subprocess.run(['systemctl', 'is-active', '--quiet', SERVICE_NAME])
    if result.returncode == 0:
        print("✅ PASO 2 COMPLETADO: Servicio activo\n")
    else:
        print("❌ Error: Servicio no se pudo iniciar")
        sys.exit(1)

#=============================================================================
# PASO 3: MODO DAEMON (SYNC AUTOMÁTICO)
#=============================================================================
def sync_files():
    """Sincronizar archivos ~/.claude/ → claude_config/"""
    changes_detected = False
    
    # Copiar archivos principales
    for claude_file, config_file in CONFIG_FILES.items():
        src = CLAUDE_DIR / claude_file
        dst = CONFIG_DIR / config_file
        
        if src.exists():
            if not dst.exists() or src.stat().st_mtime > dst.stat().st_mtime:
                shutil.copy2(src, dst)
                changes_detected = True
    
    # Copiar .claude.json
    if CLAUDE_JSON.exists():
        dst = CONFIG_DIR / ".claude.json"
        if not dst.exists() or CLAUDE_JSON.stat().st_mtime > dst.stat().st_mtime:
            shutil.copy2(CLAUDE_JSON, dst)
            changes_detected = True
    
    # Copiar directorios
    for dir_name in CONFIG_DIRS:
        src_dir = CLAUDE_DIR / dir_name
        dst_dir = CONFIG_DIR / dir_name
        
        if src_dir.exists():
            if not dst_dir.exists():
                shutil.copytree(src_dir, dst_dir)
                changes_detected = True
            else:
                # Comparar y actualizar si es necesario
                for item in src_dir.rglob('*'):
                    if item.is_file():
                        rel_path = item.relative_to(src_dir)
                        dst_item = dst_dir / rel_path
                        
                        if not dst_item.exists() or item.stat().st_mtime > dst_item.stat().st_mtime:
                            dst_item.parent.mkdir(parents=True, exist_ok=True)
                            shutil.copy2(item, dst_item)
                            changes_detected = True
    
    return changes_detected

def git_commit_and_push():
    """Hacer commit y push si hay cambios"""
    try:
        # Verificar si hay cambios
        result = subprocess.run(['git', 'diff-index', '--quiet', 'HEAD', '--'], 
                              cwd=REPO_DIR, capture_output=True)
        
        if result.returncode != 0:  # Hay cambios
            logging.info("📝 Cambios locales detectados, haciendo commit...")
            
            subprocess.run(['git', 'add', '.'], cwd=REPO_DIR, check=True)
            
            commit_msg = f"auto-sync {time.strftime('%Y-%m-%d %H:%M:%S')}"
            subprocess.run(['git', 'commit', '-m', commit_msg], cwd=REPO_DIR, check=True)
            logging.info("✅ Commit realizado")
            
            # Force push
            logging.info("🚀 Force push a GitHub...")
            subprocess.run(['git', 'push', '--force', 'origin', 'main'], 
                         cwd=REPO_DIR, check=True)
            logging.info("✅ Force push exitoso")
            return True
        else:
            logging.info("💤 No hay cambios")
            return False
            
    except subprocess.CalledProcessError as e:
        logging.error(f"❌ Error en git: {e}")
        return False

def daemon_mode():
    """Modo daemon - sync automático cada minuto"""
    print(f"🔄 MODO DAEMON: Iniciando sync automático cada {SYNC_INTERVAL} segundos...")
    setup_logging(daemon_mode=True)
    
    while True:
        try:
            logging.info("🔍 Verificando cambios...")
            
            if sync_files():
                logging.info("📝 Archivos sincronizados")
                git_commit_and_push()
            else:
                logging.info("💤 No hay cambios en archivos")
            
            logging.info(f"⏱️ Esperando {SYNC_INTERVAL} segundos hasta próximo sync...")
            time.sleep(SYNC_INTERVAL)
            
        except KeyboardInterrupt:
            logging.info("🛑 Daemon detenido por usuario")
            break
        except Exception as e:
            logging.error(f"❌ Error en daemon: {e}")
            time.sleep(10)  # Esperar antes de reintentar

#=============================================================================
# RESUMEN FINAL
#=============================================================================
def print_summary():
    """Mostrar resumen final"""
    print("🎉 INSTALACIÓN COMPLETADA!")
    print()
    print("📊 Estado del sistema:")
    print(f"• Configuración: {CLAUDE_DIR} restaurada ✅")
    print("• Servicio: claude-sync.service activo ✅")
    print(f"• Frecuencia: Sync cada {SYNC_INTERVAL} segundos ✅")
    print("• Método: Force push (sin conflictos) ✅")
    print()
    print("📋 Comandos útiles:")
    print(f"• Estado: sudo systemctl status {SERVICE_NAME}")
    print(f"• Logs: sudo journalctl -u {SERVICE_NAME} -f")
    print(f"• Logs detallados: tail -f {LOGS_DIR / 'sync.log'}")
    print("• Actualizar: python3 install.py")
    print(f"• Parar: sudo systemctl stop {SERVICE_NAME}")
    print()
    print(f"🐍 PYTHON v{SCRIPT_VERSION} - Más limpio, más robusto!")

#=============================================================================
# MAIN
#=============================================================================
def main():
    """Función principal"""
    print(f"🚀 Claude Code Config - Script Único Python v{SCRIPT_VERSION}")
    print("📦 Restaura + Servicio + Sync automático")
    print()
    
    setup_logging()
    validate_environment()
    
    # Modo daemon
    if len(sys.argv) > 1 and sys.argv[1] == '--daemon':
        daemon_mode()
        return
    
    # Instalación completa
    restore_configuration()
    install_systemd_service() 
    print_summary()

if __name__ == "__main__":
    main()