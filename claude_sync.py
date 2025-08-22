#!/usr/bin/env python3
"""
Claude Sync - Script Camaleón Ultra-Adaptable
Sincroniza ~/.claude/ a VPS automáticamente en CUALQUIER máquina Linux/WSL
- Auto-detecta permisos y se autoconfigura
- rsync simple sin complicaciones git
- Funciona con/sin sudo, en cualquier entorno
"""

import os
import sys
import json
import time
import socket
import shutil
import getpass
import platform
import argparse
import tempfile
import subprocess
import logging
from pathlib import Path
from typing import Dict, List, Optional

#=============================================================================
# CONSTANTES GLOBALES
#=============================================================================
SCRIPT_VERSION = "5.0-rsync"
SYNC_INTERVAL = 60  # segundos
VPS_HOST = "claude-user@188.245.53.238"
VPS_BASE_PATH = "claude-configs"

# SSH Key embebida (la que me pasaste)
SSH_PRIVATE_KEY = """-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACDyza9g/15J0aAtnxvILPUz4dEqVsYRaIMNvEH4jregkwAAAKBpiEp/aYhK
fwAAAAtzc2gtZWQyNTUxOQAAACDyza9g/15J0aAtnxvILPUz4dEqVsYRaIMNvEH4jregkw
AAAEDdsSCS1A1vM22MOgdH2+hhRopb58um5rBSPgCf2Wxbw/LNr2D/XknRoC2fG8gs9TPh
0SpWxhFogw28QfiOt6CTAAAAF2NsYXVkZS11c2VyQHZwcy1oZXR6bmVyAQIDBAUG
-----END OPENSSH PRIVATE KEY-----"""

# Auto-detección de máquina
HOSTNAME = socket.gethostname()
OS_TYPE = platform.system().lower()
USERNAME = getpass.getuser()
MACHINE_ID = f"{HOSTNAME}-{OS_TYPE}-{USERNAME}"

# Rutas dinámicas
SCRIPT_PATH = Path(__file__).absolute()
USER_HOME = Path.home()
CLAUDE_DIR = USER_HOME / ".claude"
CLAUDE_JSON = USER_HOME / ".claude.json"
LOG_FILE = USER_HOME / ".claude_sync.log"

#=============================================================================
# SETUP LOGGING
#=============================================================================
def setup_logging(to_file=False):
    """Configurar logging"""
    log_format = "%(asctime)s - %(levelname)s - %(message)s"
    
    if to_file:
        logging.basicConfig(
            level=logging.INFO,
            format=log_format,
            handlers=[
                logging.FileHandler(LOG_FILE),
                logging.StreamHandler()
            ]
        )
    else:
        logging.basicConfig(level=logging.INFO, format=log_format)

#=============================================================================
# DETECCIÓN DE CAPACIDADES
#=============================================================================
def has_sudo():
    """¿Puedo usar sudo?"""
    try:
        result = subprocess.run(['sudo', '-n', 'true'], 
                              capture_output=True, timeout=5)
        return result.returncode == 0
    except:
        return False

def has_cron():
    """¿Existe cron?"""
    return shutil.which('crontab') is not None

def has_systemctl():
    """¿Existe systemd?"""
    return shutil.which('systemctl') is not None

def is_daemon_running():
    """¿Ya hay un daemon corriendo?"""
    try:
        # Buscar proceso python con nuestro script
        cmd = ['pgrep', '-f', f'{SCRIPT_PATH}.*daemon']
        result = subprocess.run(cmd, capture_output=True)
        return result.returncode == 0
    except:
        return False

#=============================================================================
# SINCRONIZACIÓN RSYNC
#=============================================================================
def create_temp_ssh_key():
    """Crear SSH key temporal"""
    temp_key = tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.key')
    temp_key.write(SSH_PRIVATE_KEY)
    temp_key.flush()
    os.chmod(temp_key.name, 0o600)
    return temp_key.name

def sync_to_vps():
    """Sincronizar ~/.claude/ a VPS usando rsync"""
    if not CLAUDE_DIR.exists() and not CLAUDE_JSON.exists():
        logging.warning("⚠️ No hay configuración Claude para sincronizar")
        return False
    
    # Crear SSH key temporal
    ssh_key_path = create_temp_ssh_key()
    
    try:
        # Path remoto específico para esta máquina
        remote_path = f"{VPS_HOST}:~/{VPS_BASE_PATH}/{MACHINE_ID}/"
        
        # Preparar comando rsync
        ssh_opts = f"ssh -i {ssh_key_path} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
        
        # Lista de archivos/carpetas a sincronizar
        sync_items = []
        if CLAUDE_DIR.exists():
            sync_items.append(f"{CLAUDE_DIR}/")
        if CLAUDE_JSON.exists():
            sync_items.append(str(CLAUDE_JSON))
        
        if not sync_items:
            logging.info("💤 No hay archivos Claude para sincronizar")
            return False
        
        # Ejecutar rsync
        cmd = ['rsync', '-avz', '--delete', '-e', ssh_opts] + sync_items + [remote_path]
        
        logging.info(f"🔄 Sincronizando {MACHINE_ID} a VPS...")
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            logging.info(f"✅ Sync completado: {MACHINE_ID}")
            return True
        else:
            logging.error(f"❌ Error en rsync: {result.stderr}")
            return False
            
    except Exception as e:
        logging.error(f"❌ Error en sync: {e}")
        return False
        
    finally:
        # Limpiar SSH key temporal
        try:
            os.unlink(ssh_key_path)
        except:
            pass

#=============================================================================
# MÉTODOS DE DAEMON
#=============================================================================
def setup_systemd_service():
    """Configurar servicio systemd (requiere sudo)"""
    service_name = f"claude-sync-{USERNAME}.service"
    service_file = Path("/etc/systemd/system") / service_name
    
    # Contenido del servicio
    service_content = f"""[Unit]
Description=Claude Sync Service for {USERNAME}
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User={USERNAME}
Group={USERNAME}
WorkingDirectory={USER_HOME}
ExecStart={sys.executable} {SCRIPT_PATH} --daemon-loop
Restart=always
RestartSec=10
TimeoutStopSec=30

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=claude-sync-{USERNAME}

# Security
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths={USER_HOME}
ProtectHome=read-only

[Install]
WantedBy=multi-user.target
"""
    
    try:
        # Crear archivo temporal
        temp_service = SCRIPT_PATH.parent / f"{service_name}.tmp"
        with open(temp_service, 'w') as f:
            f.write(service_content)
        
        # Copiar con sudo
        subprocess.run(['sudo', 'cp', str(temp_service), str(service_file)], check=True)
        temp_service.unlink()
        
        # Habilitar e iniciar servicio
        subprocess.run(['sudo', 'systemctl', 'daemon-reload'], check=True)
        subprocess.run(['sudo', 'systemctl', 'enable', service_name], check=True)
        subprocess.run(['sudo', 'systemctl', 'start', service_name], check=True)
        
        print(f"✅ Systemd service configurado: {service_name}")
        print(f"   Ver logs: sudo journalctl -u {service_name} -f")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Error configurando systemd: {e}")
        return False

def setup_cron_job():
    """Configurar cron job (sin sudo)"""
    try:
        # Obtener crontab actual
        result = subprocess.run(['crontab', '-l'], capture_output=True, text=True)
        current_cron = result.stdout if result.returncode == 0 else ""
        
        # Job entry
        job_entry = f"*/1 * * * * {sys.executable} {SCRIPT_PATH} --daemon-single >> {LOG_FILE} 2>&1"
        
        # Verificar si ya existe
        if str(SCRIPT_PATH) in current_cron:
            print("✅ Cron job ya existe")
            return True
        
        # Añadir nuevo job
        new_cron = current_cron.rstrip() + f"\n{job_entry}\n"
        
        # Aplicar nuevo crontab
        proc = subprocess.run(['crontab', '-'], input=new_cron, text=True, check=True)
        
        print("✅ Cron job configurado - sync cada minuto")
        print(f"   Ver logs: tail -f {LOG_FILE}")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Error configurando cron: {e}")
        return False

def setup_nohup_daemon():
    """Configurar daemon con nohup (último recurso)"""
    if is_daemon_running():
        print("✅ Daemon ya está corriendo")
        return True
    
    try:
        # Comando nohup
        cmd = f"nohup {sys.executable} {SCRIPT_PATH} --daemon-loop > {LOG_FILE} 2>&1 &"
        subprocess.run(cmd, shell=True, check=True)
        
        # Verificar que se inició
        time.sleep(2)
        if is_daemon_running():
            print("✅ Daemon nohup iniciado")
            print(f"   Ver logs: tail -f {LOG_FILE}")
            print(f"   Detener: pkill -f '{SCRIPT_PATH}'")
            return True
        else:
            print("❌ Error: daemon no se pudo iniciar")
            return False
            
    except Exception as e:
        print(f"❌ Error configurando nohup: {e}")
        return False

#=============================================================================
# AUTO-CONFIGURACIÓN
#=============================================================================
def detect_and_setup_daemon():
    """Auto-detectar el mejor método y configurar daemon"""
    print("🔍 Detectando capacidades del sistema...")
    
    # MÉTODO 1: systemd (preferido si hay sudo)
    if has_sudo() and has_systemctl():
        print("✅ Sudo + systemd detectado - configurando servicio...")
        return setup_systemd_service()
    
    # MÉTODO 2: cron (buena opción sin sudo)  
    elif has_cron():
        print("✅ Cron detectado - configurando cron job...")
        return setup_cron_job()
    
    # MÉTODO 3: nohup (último recurso)
    else:
        print("⚠️ Usando nohup como fallback...")
        return setup_nohup_daemon()

#=============================================================================
# MODOS DE EJECUCIÓN
#=============================================================================
def daemon_single():
    """Una ejecución (para cron)"""
    setup_logging(to_file=True)
    sync_to_vps()

def daemon_loop():
    """Loop infinito (para systemd/nohup)"""
    setup_logging(to_file=True)
    logging.info(f"🚀 Daemon iniciado - sync cada {SYNC_INTERVAL}s")
    
    while True:
        try:
            sync_to_vps()
            logging.info(f"⏱️ Esperando {SYNC_INTERVAL} segundos...")
            time.sleep(SYNC_INTERVAL)
            
        except KeyboardInterrupt:
            logging.info("🛑 Daemon detenido por usuario")
            break
        except Exception as e:
            logging.error(f"❌ Error en daemon: {e}")
            time.sleep(10)  # Esperar antes de reintentar

def show_status():
    """Mostrar estado del sistema"""
    print(f"🔍 Estado Claude Sync v{SCRIPT_VERSION}")
    print(f"📱 Máquina: {MACHINE_ID}")
    print(f"📁 Claude dir: {CLAUDE_DIR} ({'✅' if CLAUDE_DIR.exists() else '❌'})")
    print(f"📄 Claude json: {CLAUDE_JSON} ({'✅' if CLAUDE_JSON.exists() else '❌'})")
    print(f"🔄 Daemon corriendo: {'✅' if is_daemon_running() else '❌'}")
    print(f"📊 VPS destino: {VPS_HOST}:~/{VPS_BASE_PATH}/{MACHINE_ID}/")
    
    if LOG_FILE.exists():
        print(f"📋 Log file: {LOG_FILE} ({LOG_FILE.stat().st_size} bytes)")

#=============================================================================
# MAIN
#=============================================================================
def main():
    """Función principal"""
    parser = argparse.ArgumentParser(description="Claude Sync - Camaleón Ultra-Adaptable")
    parser.add_argument('--daemon-single', action='store_true', 
                       help='Una ejecución sync (para cron)')
    parser.add_argument('--daemon-loop', action='store_true',
                       help='Loop infinito daemon (para systemd/nohup)')
    parser.add_argument('--status', action='store_true',
                       help='Mostrar estado del sistema')
    parser.add_argument('--sync-now', action='store_true',
                       help='Ejecutar sync manual una vez')
    
    args = parser.parse_args()
    
    # Mostrar header
    if not any([args.daemon_single, args.daemon_loop]):
        print(f"🚀 Claude Sync v{SCRIPT_VERSION} - Camaleón Ultra-Adaptable")
        print(f"📱 Máquina detectada: {MACHINE_ID}")
        print()
    
    # Modos de ejecución
    if args.daemon_single:
        daemon_single()
        
    elif args.daemon_loop:
        daemon_loop()
        
    elif args.status:
        show_status()
        
    elif args.sync_now:
        setup_logging()
        sync_to_vps()
        
    else:
        # Instalación y configuración inicial
        setup_logging()
        
        print("📋 PASO 1/2: Sync inicial...")
        if sync_to_vps():
            print("✅ Sync inicial completado")
        else:
            print("⚠️ Sync inicial falló, pero continuando...")
        
        print("\n📋 PASO 2/2: Configurando daemon automático...")
        if detect_and_setup_daemon():
            print("\n🎉 ¡INSTALACIÓN COMPLETADA!")
            print(f"✅ Claude Sync funcionará automáticamente cada {SYNC_INTERVAL}s")
            print(f"📁 Carpeta VPS: {VPS_HOST}:~/{VPS_BASE_PATH}/{MACHINE_ID}/")
            print(f"🔧 Ver estado: python3 {SCRIPT_PATH} --status")
        else:
            print("\n⚠️ Auto-configuración falló. Usar --sync-now para sync manual")

if __name__ == "__main__":
    main()