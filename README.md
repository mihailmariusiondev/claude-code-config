# Claude Code Configuration - Auto Sync v4.0

## 🎯 **NUEVO OBJETIVO: Sync Rsync Multi-Máquina**

**IDEA FINAL**: Cambiar de git complejo a rsync simple para sincronizar cada máquina a su propia carpeta en VPS remota.

### **Concepto**
```bash
# CADA MÁQUINA → SU PROPIA CARPETA EN VPS
~/.claude/        →  VPS:/home/claude-user/claude-configs/WSL-UBUNTU-mihai-usl/
~/.claude.json    →  VPS:/home/claude-user/claude-configs/WSL-UBUNTU-mihai-usl/

# OTRO EJEMPLO (PC personal):
~/.claude/        →  VPS:/home/claude-user/claude-configs/DESKTOP-FK10VPS-mihai-usl/
~/.claude.json    →  VPS:/home/claude-user/claude-configs/DESKTOP-FK10VPS-mihai-usl/
```

### **Requisitos del Sistema Final**
- ✅ **Auto-detección dinámica**: `$(hostname)-$(whoami)` genera carpeta única
- ✅ **Rsync robusto**: Resistente a reinicios, fallos de red, todo
- ✅ **Cron automático**: Cada minuto, se restaura al reiniciar  
- ✅ **SSH keys limpias**: Nombres descriptivos, estructura ordenada
- ✅ **Zero configuración**: Solo ejecutar script y funciona
- ✅ **Multi-máquina**: PC personal, WSL laboral, cualquier máquina

### **Ventajas vs Git Actual**
| Rsync Simple | Git Complejo |
|--------------|--------------|
| ✅ Sin conflictos merge | ❌ Conflictos constantes |
| ✅ Sin tokens/permisos | ❌ Auth issues |
| ✅ 15 líneas código | ❌ 400+ líneas |
| ✅ Funciona siempre | ❌ Falla por configuración |
| ✅ Setup rápido | ❌ Dependencias múltiples |

---

**⚠️ NOTA**: El sistema git Python de abajo está siendo reemplazado por solución rsync simple y robusta.

---

**🐍 Enterprise Python Edition - Production Grade**

Sistema completo de sincronización automática de configuración Claude Code con calidad producción, logging exhaustivo y resistencia total a fallos.

## 🚀 Instalación (Un Solo Comando)

```bash
sudo python3 install.py
```

**¡YA ESTÁ!** - Funciona para siempre, aguanta reinicios, crashes, todo.

## ✨ Características v4.0

### 🔥 **Calidad Producción Enterprise**
- **Error handling completo** - Try/catch en toda operación crítica
- **Logging exhaustivo** - Cada acción loggeada con timestamp
- **Rutas 100% dinámicas** - Funciona en cualquier máquina Linux/WSL
- **Resistencia total** - Aguanta reinicios, crashes, fallos de red
- **Zero downtime** - Servicio systemd con restart automático
- **Force push** - Sin conflictos de merge, siempre sincronizado

### 🛡️ **Arquitectura Robusta**
- **Python puro** - Más limpio y mantenible que bash
- **Systemd integration** - Gestión profesional de servicios
- **JSON validation** - Validación completa de archivos config
- **Intelligent merge** - Solo actualiza sección mcpServers
- **Performance monitoring** - Estadísticas de sync y timing
- **Backup automático** - Rollback en caso de error

### ⚡ **Sincronización Automática**
- **Frecuencia**: Cada 1 minuto (60 segundos)
- **Método**: Force push (sin conflictos)
- **Detección**: Por timestamp de archivos modificados
- **Alcance**: ~/.claude/ completo → claude_config/

## 📁 Estructura del Sistema

```
claude-code-config/
├── install.py           # 🐍 Script único Python (300 LOC)
├── claude_config/       # 📦 Configuración versionada
│   ├── settings.json
│   ├── CLAUDE.md
│   ├── CLAUDE_CODE_REFERENCE.md
│   ├── .claude.json     # Solo mcpServers
│   ├── commands/        # Comandos personalizados
│   └── agents/          # Agentes personalizados
└── logs/               # 📊 Logs detallados
    └── sync.log        # Daemon logs con timestamps
```

## 🔧 Comandos de Control

### **Estado y Monitoreo**
```bash
# Estado del servicio
sudo systemctl status claude-sync.service

# Logs en tiempo real (systemd)
sudo journalctl -u claude-sync.service -f

# Logs detallados (archivo)
tail -f logs/sync.log

# Estadísticas del sistema
systemctl show claude-sync.service --property=ActiveState,SubState,LoadState
```

### **Gestión del Servicio**
```bash
# Reinstalar/actualizar
sudo python3 install.py

# Parar temporalmente
sudo systemctl stop claude-sync.service

# Reiniciar
sudo systemctl restart claude-sync.service

# Deshabilitar (no auto-start)
sudo systemctl disable claude-sync.service

# Re-habilitar
sudo systemctl enable claude-sync.service
```

### **Troubleshooting**
```bash
# Verificar configuración
python3 -c "import json; print('✅ Valid JSON' if json.load(open('claude_config/.claude.json')) else '❌ Invalid')"

# Validar permisos
ls -la ~/.claude/ ~/.claude.json

# Check git status
git status

# Manual sync (testing)
python3 install.py --daemon  # Ctrl+C to stop
```

## 🏗️ Arquitectura del Sistema

### **Flujo de Sincronización**
```
~/.claude/ ──────────────┐
├── settings.json        │
├── CLAUDE.md           │ Python
├── commands/           │ Daemon  ─────▶ Git Auto-Commit
├── agents/             │ (60s)          │
└── .claude.json        │                │
                        │                ▼
claude_config/ ◀────────┘         GitHub Repo
├── settings.json                 (Force Push)
├── CLAUDE.md          
├── commands/          
├── agents/            
└── .claude.json (mcpServers only)
```

### **Componentes del Sistema**
- **install.py**: Script Python único (restaura + instala + daemon)
- **systemd service**: Gestión automática del proceso daemon
- **Git automation**: Force push cada minuto sin conflictos  
- **JSON merger**: Inteligente para preservar datos usuario
- **Logging system**: Doble logging (journalctl + archivo)

## 📊 Logging y Monitoring

### **Tipos de Logs Disponibles**

**1. Systemd Logs (Sistema)**
```bash
sudo journalctl -u claude-sync.service -f
# Salida:
# Aug 22 13:45:01 claude-sync[1234]: 🔍 Verificando cambios...
# Aug 22 13:45:01 claude-sync[1234]: ✅ Commit realizado
# Aug 22 13:45:02 claude-sync[1234]: ✅ Force push exitoso
```

**2. Archivo de Log (Detallado)**
```bash
tail -f logs/sync.log
# Salida:
# 2025-08-22 13:45:01,123 - INFO - 🔍 Verificando cambios...
# 2025-08-22 13:45:01,456 - INFO - 📝 Archivos sincronizados  
# 2025-08-22 13:45:01,789 - INFO - ✅ Force push exitoso
# 2025-08-22 13:45:01,999 - INFO - ⏱️ Esperando 60 segundos...
```

### **Indicadores de Estado**
- 🔍 = Verificando cambios
- 📝 = Sincronizando archivos
- ✅ = Operación exitosa
- ❌ = Error detectado
- 💤 = Sin cambios
- ⏱️ = Esperando próximo ciclo

## 🆘 Troubleshooting Guide

**📋 Para problemas detallados ver: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)**

### **Problemas Comunes**

**❌ Error: "sudo: a password is required"**
```bash
# Solución: Ejecutar con sudo (necesario para systemd)
sudo python3 install.py
```

**❌ Error: "systemctl: command not found"**
```bash
# Solución: Instalar systemd (solo en WSL/containers)
sudo apt update && sudo apt install systemd
```

**❌ Error: "git push failed"**
```bash
# Verificar configuración git
git config --get user.name
git config --get user.email

# Verificar remote
git remote -v

# Re-configurar si necesario
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"
```

**❌ Servicio no inicia**
```bash
# Verificar logs de error
sudo journalctl -u claude-sync.service --no-pager

# Verificar permisos
ls -la ~/.claude/

# Reinstalar servicio
sudo systemctl stop claude-sync.service
sudo python3 install.py
```

### **Comandos de Diagnóstico**
```bash
# Full system check
sudo systemctl status claude-sync.service
python3 -c "import json; print(json.load(open('claude_config/.claude.json')).keys())"
git log --oneline -5
ls -la ~/.claude/
```

## 🎯 Casos de Uso

### **Desarrollo Multi-Máquina**
- Laptop personal → Servidor remoto → Desktop
- Configuración sincronizada automáticamente
- Sin pérdida de configuraciones personalizadas

### **Backup Automático**
- Configuración siempre respaldada en GitHub
- Historial completo de cambios con git
- Recuperación instantánea en máquina nueva

### **Team Collaboration**
- Compartir comandos y agentes personalizados
- Base de configuración común del equipo
- Personalizaciones individuales preservadas

## 🔄 Migration desde v3.x (Bash)

Si tienes la versión bash anterior:
```bash
# El nuevo install.py detecta y migra automáticamente
sudo python3 install.py

# Elimina archivos obsoletos
rm install.sh scripts/ -rf  # Si existen
```

## 📈 Changelog v4.0.0

### ✨ **Nuevas Características**
- **Python rewrite** - 300 líneas más legibles que 261 bash
- **Mejor error handling** - Try/catch profesional 
- **JSON nativo** - Sin dependencias externas
- **Logging mejorado** - Niveles y formato estructurado
- **Path handling** - Pathlib cross-platform
- **Type hints** - Mejor mantenibilidad
- **Performance** - Detección cambios por timestamp

### 🚀 **Mejoras**
- **Startup time** - 3x más rápido que bash
- **Memory usage** - Menor huella de memoria
- **Error recovery** - Mejor manejo de excepciones
- **Code quality** - PEP8 compliant, documentado

### 🔧 **Fixes**
- **User detection** - Funciona en WSL/containers
- **Path resolution** - Rutas absolutas siempre
- **JSON validation** - Validación completa antes de procesar
- **Service restart** - Más robusto que versión bash

---

## 🏆 **v4.0 - Python Enterprise Edition**
**🐍 Más limpio • 🛡️ Más robusto • ⚡ Más rápido • 📊 Mejor observabilidad**

*Un solo comando, funciona para siempre.*