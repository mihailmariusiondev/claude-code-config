# Claude Code Search Configuration

## Search Rules

- **Text search** → `rg "pattern" <path>`
- **Code structure** → `ast-grep run -l <lang> -p '<pattern>' <path>`

## Claude Code Documentation Reference

**Archivos Claude Code (cuando el usuario tenga dudas sobre configuración, uso, features, troubleshooting):**
- **Referencia completa**: `~/.claude/CLAUDE_CODE_REFERENCE.md` - Documentación definitiva de Claude Code
- **Global**: `~/.claude/settings.json`, `~/.claude/CLAUDE.md`, `~/.claude/agents/*.md`, `~/.claude/commands/*.md`, `~/.config/claude-code/auth.json`
- **Local**: `.claude/settings.json`, `.claude/settings.local.json`, `CLAUDE.md`, `.claude/agents/*.md`, `.claude/commands/*.md`, `.mcp.json`
- **MCP Globales**: ⚠️ `~/.claude.json` (sección mcpServers) - USAR CLI: `claude mcp add --scope user`
- **Estado Interno**: `~/.claude.json` - NO editar manualmente, usar comandos CLI
