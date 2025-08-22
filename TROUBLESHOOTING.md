# 🚨 Claude Code Config - Troubleshooting Completo

**Guía definitiva para resolver CUALQUIER problema del sistema de sincronización v4.0**

## 📋 Índice de Problemas

- [🔴 CRÍTICO - Sistema No Funciona](#-crítico---sistema-no-funciona)
- [🟡 ADVERTENCIA - Funciona Parcialmente](#-advertencia---funciona-parcialmente)  
- [🟢 INFORMACIÓN - Dudas de Funcionamiento](#-información---dudas-de-funcionamiento)
- [🔧 Comandos de Diagnóstico](#-comandos-de-diagnóstico)
- [🆘 Recovery Total](#-recovery-total)

---

## 🔴 CRÍTICO - Sistema No Funciona

### ❌ **"sudo: a password is required"**

**CAUSA:** Systemd requiere privilegios root para instalar servicios

**SOLUCIÓN:**
```bash
# Ejecutar con sudo (es obligatorio)
sudo python3 install.py

# Si no tienes sudo, añádete al grupo sudo:
su -
usermod -aG sudo $(whoami)
exit
# Re-login y prueba de nuevo
```

**VERIFICAR:**
```bash
sudo -v  # Debe pedir password y aceptarlo
```

---

### ❌ **"systemctl: command not found"**

**CAUSA:** Sistema sin systemd (containers/WSL1 antiguos)

**SOLUCIÓN WSL2:**
```bash
# Instalar systemd
sudo apt update && sudo apt install systemd

# Habilitar systemd en WSL2
echo -e "[boot]\nsystemd=true" | sudo tee -a /etc/wsl.conf

# Reiniciar WSL
wsl --shutdown
# Reabrir terminal WSL
```

**SOLUCIÓN CONTAINERS:**
```bash
# Usar solo modo daemon (sin systemd)
python3 install.py  # Solo restore
nohup python3 install.py --daemon > logs/daemon.log 2>&1 &
```

**VERIFICAR:**
```bash
systemctl --version  # Debe mostrar versión
```

---

### ❌ **"git push failed" / "Permission denied"**

**CAUSA:** Git no configurado o sin permisos GitHub

**SOLUCIÓN CONFIGURACIÓN:**
```bash
# Verificar configuración actual
git config --get user.name
git config --get user.email
git remote -v

# Configurar si está vacío
git config --global user.name "Tu Nombre Real"
git config --global user.email "tu@email.com"

# Verificar remote correcto
git remote set-url origin https://github.com/tuusuario/claude-code-config.git
```

**SOLUCIÓN AUTENTICACIÓN:**
```bash
# Opción 1: Personal Access Token (recomendado)
git remote set-url origin https://TOKEN@github.com/usuario/repo.git

# Opción 2: SSH Key
ssh-keygen -t ed25519 -C "tu@email.com"
cat ~/.ssh/id_ed25519.pub  # Añadir a GitHub Settings > SSH Keys
git remote set-url origin git@github.com:usuario/repo.git

# Opción 3: GitHub CLI
gh auth login
```

**VERIFICAR:**
```bash
git push origin main  # Debe funcionar sin errores
```

---

### ❌ **"Service failed to start"**

**CAUSA:** Error en systemd service o permisos

**DIAGNÓSTICO COMPLETO:**
```bash
# Ver error específico
sudo journalctl -u claude-sync.service --no-pager | tail -20

# Ver status detallado  
sudo systemctl status claude-sync.service -l

# Verificar archivo de servicio
cat /etc/systemd/system/claude-sync.service

# Verificar permisos
ls -la ~/.claude/
ls -la claude_config/
```

**SOLUCIÓN:**
```bash
# Detener y limpiar servicio
sudo systemctl stop claude-sync.service
sudo systemctl disable claude-sync.service
sudo rm -f /etc/systemd/system/claude-sync.service
sudo systemctl daemon-reload

# Reinstalar completamente
sudo python3 install.py

# Verificar
sudo systemctl status claude-sync.service
```

---

### ❌ **"OSError: Unknown error -25"**

**CAUSA:** Error de detección usuario en entornos especiales

**SOLUCIÓN YA INCLUIDA EN v4.0:**
```python
# El script ya maneja este error automáticamente
CURRENT_USER = os.getenv('USER', 'unknown')
```

**SI PERSISTE:**
```bash
# Verificar variables de entorno
echo $USER
echo $HOME
whoami

# Ejecutar con variables explícitas
USER=$(whoami) HOME=$HOME python3 install.py
```

---

## 🟡 ADVERTENCIA - Funciona Parcialmente

### ⚠️ **"Sync funciona pero no hace push"**

**CAUSA:** Problemas de conectividad o permisos git

**DIAGNÓSTICO:**
```bash
# Ver logs de sync
tail -f logs/sync.log | grep -E "(ERROR|FAILED|❌)"

# Test conectividad
ping github.com
curl -I https://github.com

# Test git manual
cd /ruta/a/claude-code-config
git status
git add .
git commit -m "test"
git push origin main
```

**SOLUCIÓN:**
```bash
# Si git funciona manual pero no automático:
sudo systemctl restart claude-sync.service

# Ver logs en tiempo real
sudo journalctl -u claude-sync.service -f
```

---

### ⚠️ **"Servicio activo pero no sincroniza"**

**CAUSA:** Archivos no cambian o ruta incorrecta

**DIAGNÓSTICO:**
```bash
# Verificar que daemon está corriendo
sudo systemctl status claude-sync.service

# Ver logs daemon
tail -f logs/sync.log

# Verificar rutas
python3 -c "
from pathlib import Path
print('CLAUDE_DIR:', Path.home() / '.claude')
print('CONFIG_DIR:', Path.cwd() / 'claude_config')
print('Exists ~/.claude:', (Path.home() / '.claude').exists())
print('Exists config:', (Path.cwd() / 'claude_config').exists())
"

# Test manual de cambios
touch ~/.claude/test_file
sleep 70  # Esperar más de 1 minuto
git status  # Debe mostrar cambios
```

---

### ⚠️ **"JSON validation failed"**

**CAUSA:** Archivo .claude.json corrupto

**DIAGNÓSTICO:**
```bash
# Verificar JSON
python3 -c "
import json
try:
    with open('claude_config/.claude.json') as f:
        data = json.load(f)
    print('✅ JSON válido')
    print('Claves:', list(data.keys()))
except Exception as e:
    print(f'❌ JSON inválido: {e}')
"

# Verificar también el archivo usuario
python3 -c "
import json
from pathlib import Path
claude_json = Path.home() / '.claude.json'
if claude_json.exists():
    try:
        with open(claude_json) as f:
            data = json.load(f)
        print('✅ ~/.claude.json válido')
    except Exception as e:
        print(f'❌ ~/.claude.json inválido: {e}')
else:
    print('⚠️ ~/.claude.json no existe')
"
```

**SOLUCIÓN:**
```bash
# Restaurar desde backup
if [ -f ~/.claude.json.backup ]; then
    cp ~/.claude.json.backup ~/.claude.json
    echo "✅ Restaurado desde backup"
fi

# O regenerar limpio
mv ~/.claude.json ~/.claude.json.broken
sudo python3 install.py  # Recreará el archivo
```

---

## 🟢 INFORMACIÓN - Dudas de Funcionamiento

### ❓ **"¿Cómo sé si está funcionando?"**

**VERIFICACIÓN COMPLETA:**
```bash
# 1. Estado del servicio
sudo systemctl status claude-sync.service
# Debe mostrar: active (running)

# 2. Ver logs en tiempo real
tail -f logs/sync.log
# Debe mostrar ciclos cada 60s

# 3. Test de sync funcional
echo "test-$(date)" > ~/.claude/test-sync.txt
sleep 70  # Esperar más de 1 minuto
git log --oneline -1  # Debe mostrar commit reciente
ls claude_config/  # Debe contener test-sync.txt

# 4. Test de push
git log --oneline -5
# Debe mostrar commits "auto-sync" recientes
```

---

### ❓ **"¿Qué archivos sincroniza exactamente?"**

**ARCHIVOS SINCRONIZADOS:**
```bash
# Ver archivos que se monitorizan
python3 -c "
from pathlib import Path

claude_dir = Path.home() / '.claude'
config_files = ['settings.json', 'CLAUDE.md', 'CLAUDE_CODE_REFERENCE.md']
config_dirs = ['commands', 'agents']

print('📄 ARCHIVOS:')
for f in config_files:
    path = claude_dir / f
    status = '✅' if path.exists() else '❌'
    print(f'  {status} ~/.claude/{f}')

print('\n📁 DIRECTORIOS:')
for d in config_dirs:
    path = claude_dir / d
    status = '✅' if path.exists() else '❌'
    print(f'  {status} ~/.claude/{d}/')

print('\n🔧 ESPECIALES:')
claude_json = Path.home() / '.claude.json'
status = '✅' if claude_json.exists() else '❌'
print(f'  {status} ~/.claude.json (solo mcpServers)')
"
```

---

### ❓ **"¿Cómo cambio la frecuencia de sync?"**

**CAMBIAR INTERVALO:**
```bash
# Editar constante en install.py
sed -i 's/SYNC_INTERVAL = 60/SYNC_INTERVAL = 300/' install.py  # 5 minutos
# O editar manualmente línea 18: SYNC_INTERVAL = 300

# Reinstalar servicio
sudo python3 install.py

# Verificar cambio
grep "SYNC_INTERVAL" install.py
sudo journalctl -u claude-sync.service -f  # Ver nuevo intervalo
```

---

## 🔧 Comandos de Diagnóstico

### **🔍 Diagnóstico Completo del Sistema**

```bash
#!/bin/bash
# SUPER DIAGNÓSTICO - Copia y ejecuta todo

echo "🔍 === DIAGNÓSTICO CLAUDE CODE CONFIG v4.0 ==="
echo "📅 $(date)"
echo

echo "📊 ESTADO DEL SISTEMA:"
echo "• Usuario actual: $(whoami)"
echo "• Directorio trabajo: $(pwd)"
echo "• Python version: $(python3 --version)"
echo "• Git version: $(git --version)"
echo

echo "🛡️ ESTADO SYSTEMD:"
if command -v systemctl >/dev/null 2>&1; then
    echo "• Systemctl: ✅ Disponible"
    sudo systemctl status claude-sync.service --no-pager | head -10
else
    echo "• Systemctl: ❌ No disponible"
fi
echo

echo "📁 ESTRUCTURA ARCHIVOS:"
echo "• install.py: $([ -f install.py ] && echo '✅' || echo '❌')"
echo "• claude_config/: $([ -d claude_config ] && echo '✅' || echo '❌')"  
echo "• logs/: $([ -d logs ] && echo '✅' || echo '❌')"
echo "• ~/.claude/: $([ -d ~/.claude ] && echo '✅' || echo '❌')"
echo "• ~/.claude.json: $([ -f ~/.claude.json ] && echo '✅' || echo '❌')"
echo

echo "🔧 CONFIGURACIÓN GIT:"
echo "• user.name: $(git config --get user.name || echo 'NO CONFIGURADO')"
echo "• user.email: $(git config --get user.email || echo 'NO CONFIGURADO')"
echo "• remote: $(git remote get-url origin 2>/dev/null || echo 'NO CONFIGURADO')"
echo

echo "📊 ÚLTIMOS LOGS:"
if [ -f logs/sync.log ]; then
    echo "• sync.log (últimas 5 líneas):"
    tail -5 logs/sync.log | sed 's/^/    /'
else
    echo "• sync.log: ❌ No existe"
fi
echo

echo "🔍 ÚLTIMOS COMMITS:"
git log --oneline -5 | sed 's/^/    /'
echo

echo "🌐 CONECTIVIDAD:"
if ping -c 1 github.com >/dev/null 2>&1; then
    echo "• GitHub: ✅ Conectado"
else
    echo "• GitHub: ❌ Sin conexión"
fi

echo
echo "🎯 RESUMEN:"
if systemctl is-active --quiet claude-sync.service 2>/dev/null; then
    echo "• Servicio: ✅ ACTIVO"
else
    echo "• Servicio: ❌ INACTIVO"
fi

if [ -f ~/.claude/settings.json ] && [ -f claude_config/settings.json ]; then
    echo "• Archivos: ✅ SINCRONIZADOS"
else
    echo "• Archivos: ❌ DESINCRONIZADOS" 
fi

if git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "• Git: ✅ LIMPIO"
else
    echo "• Git: ⚠️ CAMBIOS PENDIENTES"
fi

echo
echo "🆘 SI HAY PROBLEMAS:"
echo "1. sudo python3 install.py  # Reinstalar"
echo "2. sudo journalctl -u claude-sync.service -f  # Ver logs"
echo "3. tail -f logs/sync.log  # Ver sync detallado"
```

### **🚨 Test de Funcionalidad End-to-End**

```bash
#!/bin/bash
# TEST E2E - Verifica todo el flujo

echo "🧪 === TEST END-TO-END CLAUDE CODE CONFIG ==="
echo

# 1. Crear archivo test
test_file="test-e2e-$(date +%s).txt"
echo "Testing sync at $(date)" > ~/.claude/$test_file
echo "✅ 1. Archivo test creado: ~/.claude/$test_file"

# 2. Esperar 2 ciclos de sync (130 segundos)
echo "⏳ 2. Esperando 2 minutos y 10 segundos para sync..."
for i in {130..1}; do
    printf "\r   Restando: %d segundos " $i
    sleep 1
done
printf "\n"

# 3. Verificar sync local
if [ -f "claude_config/$test_file" ]; then
    echo "✅ 3. Archivo sincronizado localmente"
else
    echo "❌ 3. FALLO: Archivo NO sincronizado localmente"
fi

# 4. Verificar commit
if git log --oneline -1 | grep -q "auto-sync"; then
    echo "✅ 4. Commit automático realizado"
else
    echo "❌ 4. FALLO: No hay commit automático"
fi

# 5. Verificar push remoto
if git status | grep -q "up to date"; then
    echo "✅ 5. Push remoto exitoso"
else
    echo "⚠️ 5. ADVERTENCIA: Push puede estar pendiente"
fi

# 6. Cleanup
rm -f ~/.claude/$test_file claude_config/$test_file
git add . && git commit -m "cleanup test e2e" && git push
echo "✅ 6. Limpieza completada"

echo
echo "🎯 RESULTADO:"
echo "Si todos los pasos muestran ✅, el sistema funciona perfectamente."
```

---

## 🆘 Recovery Total

### **🔥 RESET COMPLETO - Última Opción**

**CUANDO TODO FALLA:**
```bash
#!/bin/bash
# RESET NUCLEAR - Solo usar si todo está roto

echo "🔥 === RESET NUCLEAR CLAUDE CODE CONFIG ==="
read -p "⚠️ Esto BORRARÁ todo y empezará desde cero. ¿Continuar? [y/N]: " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelado"
    exit 1
fi
echo

# 1. Backup de seguridad
echo "💾 1. Creando backup de emergencia..."
mkdir -p ~/backup-claude-emergency-$(date +%Y%m%d)
cp -r ~/.claude ~/backup-claude-emergency-$(date +%Y%m%d)/ 2>/dev/null || true
cp ~/.claude.json ~/backup-claude-emergency-$(date +%Y%m%d)/ 2>/dev/null || true
echo "✅ Backup en ~/backup-claude-emergency-$(date +%Y%m%d)/"

# 2. Detener y eliminar servicio
echo "🛑 2. Eliminando servicio systemd..."
sudo systemctl stop claude-sync.service 2>/dev/null || true
sudo systemctl disable claude-sync.service 2>/dev/null || true  
sudo rm -f /etc/systemd/system/claude-sync.service
sudo systemctl daemon-reload
echo "✅ Servicio eliminado"

# 3. Limpiar archivos locales
echo "🧹 3. Limpiando archivos..."
rm -rf logs/
mkdir -p logs
echo "✅ Logs reiniciados"

# 4. Reset git
echo "🔄 4. Reiniciando git..."
git reset --hard HEAD~10  # Volver 10 commits atrás
git clean -fd
echo "✅ Git reiniciado"

# 5. Reinstalación completa
echo "🚀 5. Reinstalación completa..."
sudo python3 install.py
echo "✅ Sistema reinstalado"

# 6. Verificación
echo "🔍 6. Verificando instalación..."
sleep 5
if systemctl is-active --quiet claude-sync.service; then
    echo "✅ Servicio activo"
else
    echo "❌ FALLO: Servicio no activo"
fi

echo
echo "🎯 RESET COMPLETADO"
echo "📁 Backup en: ~/backup-claude-emergency-$(date +%Y%m%d)/"
echo "🔧 Monitor: tail -f logs/sync.log"
echo "📊 Status: sudo systemctl status claude-sync.service"
```

### **📋 Checklist Post-Recovery**

```bash
# EJECUTAR DESPUÉS DEL RESET:

# ✅ 1. Verificar servicio
sudo systemctl status claude-sync.service

# ✅ 2. Ver logs primeros minutos  
tail -f logs/sync.log

# ✅ 3. Test funcionalidad
echo "recovery-test-$(date)" > ~/.claude/recovery-test.txt
sleep 70
ls claude_config/recovery-test.txt  # Debe existir

# ✅ 4. Verificar push
git log --oneline -3

# ✅ 5. Configurar git si necesario
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"

# ✅ 6. Test final
python3 -c "print('🎯 Recovery completado - Sistema operativo')"
```

---

## 📞 **CONTACTO DE EMERGENCIA**

Si nada de esta guía funciona:

1. **Copia TODO el output** del diagnóstico completo
2. **Incluye logs específicos** del error
3. **Especifica tu entorno** (WSL1/WSL2, Ubuntu version, etc.)
4. **Describe qué intentaste** antes del problema

**⚠️ IMPORTANTE:** Nunca borres los backups automáticos (archivos `.backup`) hasta confirmar que todo funciona.

---

**🤖 v4.0 Enterprise Troubleshooting Guide**  
*Para cualquier problema, hay una solución documentada.*