# Claude Code Configuration Sync

> 🚀 **UN SOLO SCRIPT PARA TODO**

Sistema ultra-simple: **un solo archivo** hace restore, servicio y sync automático cada 1 minuto.

## ⚡ Qué Hace

- **UN SOLO SCRIPT** - `install.sh` hace TODO 
- **Sync cada 1 minuto** - Copia `~/.claude/` → GitHub automático
- **Force push siempre** - Sin conflictos jamás, machaca remoto
- **Auto-inicio** - Funciona al arrancar WSL/Linux
- **Cero carpetas** - Solo `install.sh` en la raíz

## 📁 Archivos Sincronizados

- `~/.claude/settings.json` - Configuración global
- `~/.claude/CLAUDE.md` - Instrucciones personales  
- `~/.claude/CLAUDE_CODE_REFERENCE.md` - Documentación
- `~/.claude/commands/` - Comandos slash personalizados
- `~/.claude/agents/` - Subagentes especializados
- `~/.claude.json` - MCP servers (merge inteligente)

## 🛠️ Instalación (2 comandos)

### Nueva Máquina
```bash
git clone https://github.com/mihailmariusiondev/claude-code-config.git
cd claude-code-config && ./install.sh
```

### Máquina Existente  
```bash
cd claude-code-config && ./install.sh
```

## 🔧 Gestión (Todo desde `install.sh`)

### Actualizar/Reinstalar
```bash
./install.sh  # Hace TODO: restore + servicio + sync
```

### Comandos Básicos  
```bash
# Estado
sudo systemctl status claude-sync.service

# Logs en tiempo real  
sudo journalctl -u claude-sync.service -f
tail -f logs/sync.log

# Parar/Iniciar
sudo systemctl stop claude-sync.service
sudo systemctl start claude-sync.service
```

## 🔄 Cómo Funciona (Ultra-Simple)

```
                    UN SOLO SCRIPT
                    
~/.claude/  →  claude_config/  →  GitHub (force push)
   ↑              ↑                   ↑
Original     Git tracking         Remoto machacado
(untouched)   (auto-commit)       (siempre gana local)
```

**`install.sh` hace:**
1. **Restore**: `claude_config/` → `~/.claude/`
2. **Servicio**: Crea systemd que ejecuta `install.sh --daemon`
3. **Daemon**: Loop infinito cada 1 minuto con force push

## 🚨 Troubleshooting

### Servicio no funciona
```bash
# Ver errores
sudo systemctl status claude-sync.service
sudo journalctl -u claude-sync.service -p err

# Reinstalar
./install.sh
```

### No hace push
```bash
# Verificar git auth
git push origin main

# Ver logs
tail -f logs/sync.log | grep ERROR

# Conectividad
ping github.com
```

### Restaurar en nueva máquina
```bash
# Si falla restore
./scripts/restore.sh
ls -la ~/.claude/
```

## ⚙️ Configuración

### Cambiar frecuencia
```bash
# Editar intervalo en install.sh (buscar "sleep 60")
sed -i 's/sleep 60/sleep 300/' install.sh   # 5 minutos  
./install.sh  # Aplicar cambios
```

### Ver estadísticas
```bash
# Logs detallados
tail -f logs/sync.log

# Estado del servicio
sudo systemctl status claude-sync.service
```

## 🏗️ Arquitectura: 1 Script = Everything

```
┌──────────────────────────────────────────┐
│              install.sh                  │
│  ┌─────────┐ ┌─────────┐ ┌─────────────┐ │
│  │ Restore │ │ Service │ │ Daemon Loop │ │  
│  │   Step  │ │  Setup  │ │ (1 min sync)│ │
│  └─────────┘ └─────────┘ └─────────────┘ │
└──────────────────────────────────────────┘
                     │
                     ▼
        Force push → GitHub (always wins)
```

**Un archivo. Todo resuelto. Zero bullshit.**

## 📊 Stats

- **Archivos**: 1 solo script (`install.sh`)
- **Carpetas extras**: 0 (eliminada `scripts/`)  
- **Frecuencia**: 1 minuto sync automático
- **Conflictos**: 0 (force push siempre)
- **Nueva máquina**: 2 comandos, listo
- **Actualizar**: 1 comando, listo

---

**🤖 Version 3.3 - UN SOLO SCRIPT PARA TODO**  
*Zero folders. Zero bullshit. Just works.*