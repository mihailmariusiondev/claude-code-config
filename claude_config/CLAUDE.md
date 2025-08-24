# Que es este documento
- ⚠️ Este documento actúa como un mapa: no contiene detalles técnicos, solo te dirige al lugar correcto según lo que necesites. Su función es guiar, no explicar, es solo para referencia rápida.
- También define reglas generales de comportamiento PARA TI (claude) que deberas seguir en todo momento y aplicar en todas las sesiones
- JAMÁS escribirás aquí extensamente, las únicas ediciones PERMITIDAS que deberán hacerse sobre este documento serán breves siguiendo el formato de lo ya existente en las secciones de abajo
- Si necesitas información sobre algo -> lee el archivo específico entero

## Reglas generales para ti (Claude) a seguir en todo momento

- **TODO el código debe ser production-ready con manejo de errores, validación y mejores prácticas**
- **Búsqueda texto** → `rg "pattern" <path>`
- **Estructura código** → `ast-grep run -l <lang> -p '<pattern>' <path>`

## Rutas Importantes del Sistema

- **~/repos/personal** - Repositorios personales y side projects: experimentos propios, desarrollo independiente, pruebas de concepto, proyectos hobby, testing de tecnologías, portfolios personales, prototipos, aprendizaje
- **~/repos/laboral** - Repositorios profesionales: proyectos empresa, trabajo corporativo, colaboraciones laborales, código privado empresa, desarrollos cliente, proyectos con NDA, integraciones corporativas
- **~/mcp-servers** - MCP servers clonados manualmente: método alternativo cuando npx/uvx/instalación directa no funciona por restricciones empresa/firewall/red. Se clona el repo git del MCP server y se configura en ~/.claude.json usando "command" del lenguaje (node/python/go/rust/etc.) con "args" apuntando al archivo ejecutable principal (index.js, main.py, etc.). Ejemplo: "command": "node", "args": ["~/mcp-servers/puppeteer-mcp/index.js"] en lugar de "command": "npx", "args": ["-y", "puppeteer-mcp-server"]
- **~/scripts** - Scripts utilitarios globales: bash/python/shell para automatización sistema, crontabs, herramientas personales reutilizables, utilidades desarrollo, scripts deployment, backups, monitoreo, sincronización, maintenance
- **~/docs** - Documentación y conocimiento personal: apuntes técnicos, referencias arquitectura, guías desarrollo, manuales configuración, tutoriales, investigación acumulada, notas reuniones, decisiones técnicas, troubleshooting, best practices
  - **~/docs/obsidian-segundo-cerebro/** - 🧠 Segundo Cerebro Obsidian + Claude MCP (ver README.md completo)
- **~/CLAUDE.md** - Guía técnica completa del VPS Ubuntu 24.04 (Hetzner): infraestructura, comandos, configuraciones sistema, 4 bots Telegram + VNC + Obsidian + scripts, troubleshooting y procedimientos operativos

## Referencia Documentación Claude Code

**Archivos Claude Code (cuando el usuario tenga dudas sobre configuración, uso, features, troubleshooting):**

- **Referencia completa**: `~/.claude/CLAUDE_CODE_REFERENCE.md` - Documentación definitiva de Claude Code
- **Global**: `~/.claude/settings.json`, `~/.claude/CLAUDE.md`, `~/.claude/agents/*.md`, `~/.claude/commands/*.md`, `~/.config/claude-code/auth.json`
- **Local**: `.claude/settings.json`, `.claude/settings.local.json`, `CLAUDE.md`, `.claude/agents/*.md`, `.claude/commands/*.md`, `.mcp.json`
- **MCP Globales**: ⚠️ `~/.claude.json` (sección mcpServers) - USAR CLI: `claude mcp add --scope user`
- **Estado Interno**: `~/.claude.json` - NO editar manualmente, usar comandos CLI
