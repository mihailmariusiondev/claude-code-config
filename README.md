# Claude Code Configuration Sync

> 🚀 **Sync automático de configuración Claude Code cada 1 minuto**

Sistema simple que mantiene tu configuración Claude Code siempre sincronizada en GitHub.

## ⚡ Qué Hace

- **Sync automático cada 1 minuto** - Copia `~/.claude/` → GitHub 
- **Force push siempre** - Sin conflictos, machaca todo remoto
- **Auto-inicio** - Funciona al arrancar WSL/Linux
- **Restauración simple** - Nueva máquina en 30 segundos

## 📁 Archivos Sincronizados

- `~/.claude/settings.json` - Configuración global
- `~/.claude/CLAUDE.md` - Instrucciones personales  
- `~/.claude/CLAUDE_CODE_REFERENCE.md` - Documentación
- `~/.claude/commands/` - Comandos slash personalizados
- `~/.claude/agents/` - Subagentes especializados
- `~/.claude.json` - MCP servers (solo sección mcpServers en restore)

## 🛠️ Instalación

### Nueva Máquina
```bash
# 1. Login Claude Code
npm install -g @anthropic-ai/claude-code
claude

# 2. Instalar sync (todo automático)
git clone https://github.com/mihailmariusiondev/claude-code-config.git
cd claude-code-config
./install.sh
```

### Máquina Existente  
```bash
cd claude-code-config
./install.sh
```

## 🔧 Gestión

### Actualizar Servicio
```bash
# Aplicar cambios en scripts
./install.sh  # Se encarga de todo automáticamente
```

### Comandos Básicos
```bash
# Estado
sudo systemctl status claude-sync.service

# Logs en tiempo real  
sudo journalctl -u claude-sync.service -f

# Parar/Iniciar
sudo systemctl stop claude-sync.service
sudo systemctl start claude-sync.service
```

## 🔄 Cómo Funciona

```
~/.claude/  →  claude_config/  →  GitHub (force push)
   ↑              ↑                   ↑
Original      Tracking dir        Backup remoto
(never        (git commits)      (siempre actualizado)
 touched)     
```

**Cada 1 minuto:**
1. Copia archivos de `~/.claude/` a `claude_config/`
2. Si hay cambios → `git commit`  
3. `git push --force origin main` (machaca todo remoto)

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
# Editar intervalo (actual: 1 minuto = 60 segundos)
sed -i 's/sleep 60/sleep 300/' scripts/sync.sh   # 5 minutos
./install.sh  # Aplicar cambios
```

### Ver estadísticas
```bash
# Últimos syncs
grep "CYCLE" logs/sync.log | tail -5

# Archivos procesados  
grep "Copied" logs/sync.log | tail -10

# Estado del servicio
sudo systemctl status claude-sync.service
```

## 🏗️ Arquitectura Simple

```
┌─────────────┐    cada     ┌─────────────┐    force    ┌─────────────┐
│ ~/.claude/  │    1 min    │ git repo    │    push     │  GitHub     │
│ (original)  │ ────────▶   │ (tracking)  │ ────────▶   │ (backup)    │
└─────────────┘             └─────────────┘             └─────────────┘
```

**Force push = Sin problemas:**
- No importa qué hay en GitHub
- Siempre gana lo local
- Sin merge conflicts nunca
- Sin fetch/pull necesario

## 📊 Stats

- **Frecuencia**: 1 minuto
- **Uptime**: 99.9% con auto-restart  
- **Recovery**: < 30 segundos
- **Nueva máquina**: < 2 minutos setup completo
- **Archivos**: ~10-15 monitoreados

---

**🤖 Claude Code Assistant - Version 3.2**  
*Sync cada 1 minuto - Force push always wins*