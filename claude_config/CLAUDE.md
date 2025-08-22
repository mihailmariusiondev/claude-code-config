# Claude Code Configuration

## General Rules

- **ALL code must be production-ready with proper error handling, validation, and best practices**

## Search Rules

- **Text search** → `rg "pattern" <path>`
- **Code structure** → `ast-grep run -l <lang> -p '<pattern>' <path>`

## Rutas Importantes del Sistema

- **~/repos/personal** - Repositorios personales y side projects: experimentos propios, desarrollo independiente, pruebas de concepto, proyectos hobby, testing de tecnologías, portfolios personales, prototipos, aprendizaje
- **~/repos/laboral** - Repositorios profesionales: proyectos empresa, trabajo corporativo, colaboraciones laborales, código privado empresa, desarrollos cliente, proyectos con NDA, integraciones corporativas
- **~/mcp-servers** - MCP servers clonados manualmente: método alternativo cuando npx/uvx/instalación directa no funciona por restricciones empresa/firewall/red. Se clona el repo git del MCP server y se configura en ~/.claude.json usando "command" del lenguaje (node/python/go/rust/etc.) con "args" apuntando al archivo ejecutable principal (index.js, main.py, etc.). Ejemplo: "command": "node", "args": ["~/mcp-servers/puppeteer-mcp/index.js"] en lugar de "command": "npx", "args": ["-y", "puppeteer-mcp-server"]
- **~/scripts** - Scripts utilitarios globales: bash/python/shell para automatización sistema, crontabs, herramientas personales reutilizables, utilidades desarrollo, scripts deployment, backups, monitoreo, sincronización, maintenance
- **~/docs** - Documentación y conocimiento personal: apuntes técnicos, referencias arquitectura, guías desarrollo, manuales configuración, tutoriales, investigación acumulada, notas reuniones, decisiones técnicas, troubleshooting, best practices

## Claude Code Documentation Reference

**Archivos Claude Code (cuando el usuario tenga dudas sobre configuración, uso, features, troubleshooting):**

- **Referencia completa**: `~/.claude/CLAUDE_CODE_REFERENCE.md` - Documentación definitiva de Claude Code
- **Global**: `~/.claude/settings.json`, `~/.claude/CLAUDE.md`, `~/.claude/agents/*.md`, `~/.claude/commands/*.md`, `~/.config/claude-code/auth.json`
- **Local**: `.claude/settings.json`, `.claude/settings.local.json`, `CLAUDE.md`, `.claude/agents/*.md`, `.claude/commands/*.md`, `.mcp.json`
- **MCP Globales**: ⚠️ `~/.claude.json` (sección mcpServers) - USAR CLI: `claude mcp add --scope user`
- **Estado Interno**: `~/.claude.json` - NO editar manualmente, usar comandos CLI

# important-instruction-reminders

Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (\*.md) or README files. Only create documentation files if explicitly requested by the User.

TEST
