# Claude Code - Guía de Referencia Definitiva

> **Documentación completa y estructurada para usar Claude Code como un profesional**

---

## ⚠️ DISCLAIMER CRÍTICO - CONFLICTOS DE CONFIGURACIÓN

**ANTES DE TOCAR NADA, LEE ESTO O TE VOLVERÁS LOCO** 🤬

### 🎯 LA CONFUSIÓN MÁS IMPORTANTE: Estado vs Configuración

Claude Code usa **DOS TIPOS DE ARCHIVOS COMPLETAMENTE DIFERENTES**:

#### 📁 ARCHIVOS DE CONFIGURACIÓN (Los que TÚ editas)
- `~/.claude/settings.json` - **TUS REGLAS GLOBALES** 
- `./.claude/settings.json` - **REGLAS DEL PROYECTO**
- `./.claude/settings.local.json` - **TUS REGLAS PERSONALES DEL PROYECTO**
- `./.mcp.json` - **SERVIDORES MCP DEL PROYECTO**
- `CLAUDE.md` - **INSTRUCCIONES Y MEMORIA**

#### 🗄️ ARCHIVOS DE ESTADO INTERNO (Los que CLAUDE escribe)
- `~/.claude.json` - **BASE DE DATOS INTERNA DE CLAUDE** ❌ **NO TOCAR**

### 🔥 CONFLICTOS PRINCIPALES QUE TE JODERÁN

#### 1. **MCP Servers - El Más Confuso**
```bash
# ❌ PROBLEMA: MCPs solo en un proyecto
claude mcp add zen -- comando    # Se guarda en ~/.claude.json SOLO para ese directorio

# ✅ SOLUCIÓN: MCPs globales por comando
claude mcp add --scope user zen -- comando    # Disponible en TODOS los proyectos
```

#### 2. **Permissions - Se Acumulan Mal**
```json
// Global: Permites git
"allow": ["Bash(git*)"]

// Proyecto: Quieres bloquear push  
"deny": ["Bash(git push*)"]    // ✅ deny gana, se bloquea push

// Pero al revés:
// Global: Bloqueas git
"deny": ["Bash(git*)"] 

// Proyecto: Quieres permitir status
"allow": ["Bash(git status*)"]    // ❌ deny SIEMPRE gana, status sigue bloqueado
```

#### 3. **Environment Variables - Se Sobrescriben**
```json
// Global
"env": {"NODE_ENV": "development"}

// Proyecto sobrescribe completamente
"env": {"NODE_ENV": "production", "API_URL": "local"}
```

### 🎯 REGLAS DE ORO

1. **MCPs globales**: SIEMPRE usar `claude mcp add --scope user`
2. **Permissions**: `deny` gana SIEMPRE, úsalo con cuidado  
3. **Estado interno**: NO editar `~/.claude.json` a mano
4. **Debugging**: Usar `claude config list` para ver configuración efectiva
5. **Enterprise**: Si algo no funciona, pregunta al admin por `managed-settings.json`

---

## 🚀 Quick Start - Lo Esencial en 5 Minutos

### Instalación
```bash
# Instalación estándar
npm install -g @anthropic-ai/claude-code

# Instalación nativa (recomendada)
curl -fsSL https://claude.ai/install.sh | bash  # Linux/macOS/WSL
```

### Primer Uso
```bash
cd tu-proyecto
claude                    # Modo interactivo
claude "analiza este código"  # Tarea única
```

### MCP Servers Globales (Funcionalidad Avanzada)
```bash
# Configurar una vez, usar en todos los proyectos
claude mcp add --scope user nombre-servidor -- comando

# O editar manualmente ~/.claude.json:
# Añadir en sección "mcpServers": { "tu-servidor": {...} }
```

### Comandos Más Útiles
```bash
/help                     # Lista todos los comandos
/config                   # Configuración interactiva
/mcp                     # Gestión servidores MCP
claude commit            # Auto-commit inteligente
```

---

## 📁 Sistema de Archivos de Configuración

### Jerarquía por Prioridad (Mayor → Menor)
1. **CLI flags** (`--model`, `--permission-mode`)
2. **Enterprise/Managed** (`/etc/claude-code/managed-settings.json`)
3. **Proyecto Local Personal** (`./.claude/settings.local.json`)
4. **Proyecto Compartido** (`./.claude/settings.json`, `./.mcp.json`)
5. **Usuario Global** (`~/.claude/settings.json`)
6. **Estado Interno Claude** (`~/.claude.json` - ⚠️ **NO editar manualmente**)

### Mapa de Archivos por Función

| Función | Archivo | Ubicación | Descripción |
|---------|---------|-----------|-------------|
| **Configuración Global** | `settings.json` | `~/.claude/` | Permisos, env vars, hooks globales |
| **MCP Globales** | `.claude.json` | `~/` | **ESTADO INTERNO CLAUDE** - Servidores MCP globales (NO editar manualmente) |
| **Instrucciones Globales** | `CLAUDE.md` | `~/.claude/` | Preferencias personales, estilo |
| **Configuración Proyecto** | `settings.json` | `./.claude/` | Permisos y reglas del proyecto |
| **MCP Proyecto** | `.mcp.json` | `./` | Servidores MCP específicos del proyecto |
| **Instrucciones Proyecto** | `CLAUDE.md` | `./` | Arquitectura, comandos, convenciones |
| **Comandos Personalizados** | `*.md` | `~/.claude/commands/` | Comandos slash personales |
| **Subagentes** | `*.md` | `~/.claude/agents/` | Asistentes especializados |

---

## ⚙️ Configuración Global (settings.json)

### Ubicación: `~/.claude/settings.json`

### Configuraciones Esenciales
```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(git diff:*)", 
      "Read(~/.zshrc)"
    ],
    "deny": [
      "Read(./.env*)",
      "Read(./secrets/**)",
      "Bash(rm -rf *)"
    ],
    "defaultMode": "acceptEdits"
  },
  "enableAllProjectMcpServers": true,
  "includeCoAuthoredBy": false,
  "env": {
    "NODE_ENV": "development"
  }
}
```

### Todas las Opciones Disponibles

| Clave | Tipo | Descripción | Ejemplo |
|-------|------|-------------|---------|
| `permissions` | `object` | Control de herramientas y comandos | Ver tabla detallada abajo |
| `enableAllProjectMcpServers` | `boolean` | Auto-aprobar MCPs del proyecto | `true` |
| `enabledMcpjsonServers` | `array` | Lista específica MCPs a aprobar | `["memory", "github"]` |
| `disabledMcpjsonServers` | `array` | Lista específica MCPs a rechazar | `["filesystem"]` |
| `model` | `string` | Modelo por defecto | `"claude-3-5-sonnet-20241022"` |
| `env` | `object` | Variables de entorno | `{"NODE_ENV": "dev"}` |
| `includeCoAuthoredBy` | `boolean` | Firma en commits (default: true) | `false` |
| `cleanupPeriodDays` | `number` | Días conservar chats (default: 30) | `15` |
| `forceLoginMethod` | `string` | Método login: "claudeai"/"console" | `"claudeai"` |
| `apiKeyHelper` | `string` | Script para obtener API key | `"/usr/local/bin/get_key.sh"` |
| `statusLine` | `object` | Status line personalizado | Ver ejemplo abajo |
| `hooks` | `object` | Scripts en eventos | Ver ejemplo abajo |

### Sistema de Permisos Detallado

| Tipo | Descripción | Precedencia |
|------|-------------|-------------|
| `deny` | Siempre bloquear | **Máxima** (gana siempre) |
| `ask` | Siempre pedir confirmación | Media |
| `allow` | Permitir sin preguntar | Mínima |

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",          // Cualquier comando npm run
      "Bash(git diff:*)",         // git diff con argumentos
      "Read(./src/**)",           // Leer directorio src
      "mcp__github__*"            // Todas las herramientas del MCP github
    ],
    "ask": [
      "Bash(git push:*)",         // Siempre confirmar push
      "Write(./config/**)"        // Confirmar cambios config
    ],
    "deny": [
      "Bash(rm -rf *)",          // Nunca permitir rm -rf
      "Read(./.env*)",           // Bloquear archivos env
      "WebFetch",                // Bloquear herramienta completa
      "Write(//prod_configs/*)"  // Bloquear configs producción
    ],
    "additionalDirectories": [
      "../shared-library",        // Acceso a directorios extra
      "~/tools"
    ],
    "defaultMode": "acceptEdits"   // Modo por defecto
  }
}
```

### Status Line Personalizado
```json
{
  "statusLine": {
    "type": "command",
    "command": "TIME=$(date +%H:%M); BRANCH=$(git branch --show-current 2>/dev/null); printf '\\033[36m%s\\033[0m@\\033[32m%s\\033[0m \\033[35m%s\\033[0m' \"$(whoami)\" \"$(basename $(pwd))\" \"$BRANCH\""
  }
}
```

### Hooks (Scripts en Eventos)
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "npm run lint:fix",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

---

## 🔌 MCP Servers - Configuración Global

### ⚠️ UBICACIÓN CORRECTA PARA MCPS GLOBALES

```
✅ CORRECTO: ~/.claude.json (sección "mcpServers")
❌ INCORRECTO: ~/.claude/.mcp.json
❌ INCORRECTO: ~/.claude/settings.json
```

### Configurar MCP Globales

**Método 1: CLI (ÚNICO MÉTODO RECOMENDADO)**
```bash
# Agregar servidor global
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp

# Agregar con variables de entorno
claude mcp add --scope user zen --env OPENROUTER_API_KEY=tu-key -- python /path/to/server.py

# Verificar que sea global
claude mcp list  # Debe mostrar Scope: "User"
```

**Método 2: Edición Manual ~/.claude.json (⚠️ NO RECOMENDADO)**
```json
{
  "// ... ADVERTENCIA: Este es el archivo de ESTADO INTERNO de Claude": "...",
  "// ... Contiene historial de proyectos, configuración interna, etc.": "...",
  "// ... EDITAR MANUALMENTE puede corromper tu configuración": "...",
  "mcpServers": {
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "env": {}
    },
    "zen": {
      "type": "stdio",
      "command": "/home/user/mcp-servers/zen/.zen_venv/bin/python",
      "args": ["/home/user/mcp-servers/zen/server.py"],
      "env": {
        "OPENROUTER_API_KEY": "tu-key",
        "CUSTOM_MODELS_CONFIG_PATH": "/path/to/config.json"
      }
    }
  }
}
```

> ⚠️ **ADVERTENCIA CRÍTICA**: `~/.claude.json` es el archivo de **ESTADO INTERNO** de Claude Code. Contiene historial de proyectos, cache, configuración interna y puede ser **muy grande** (varios MB). **Editar manualmente es PELIGROSO** y puede corromper tu instalación. **SIEMPRE usa el CLI** (`claude mcp add --scope user`) en su lugar.

### MCP por Proyecto (`.mcp.json`)
```json
{
  "mcpServers": {
    "database": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub"],
      "env": {
        "DB_DSN": "${DATABASE_URL}"
      }
    },
    "linear": {
      "type": "sse",
      "url": "https://mcp.linear.app/sse",
      "authentication": {
        "type": "oauth"
      }
    }
  }
}
```

### Auto-Aprobación MCPs
```json
// En ~/.claude/settings.json
{
  "enableAllProjectMcpServers": true,        // Aprobar todos los del proyecto
  "enabledMcpjsonServers": ["linear", "db"], // O solo específicos
  "disabledMcpjsonServers": ["risky-server"] // Bloquear específicos
}
```

---

## 📝 Memory Files (CLAUDE.md)

### Jerarquía de Instrucciones
1. **Global**: `~/.claude/CLAUDE.md` - Preferencias personales
2. **Proyecto**: `./CLAUDE.md` - Arquitectura, convenciones del proyecto

### Sintaxis Especial
- `@path/to/file` - Importar contenido de otro archivo
- `@~/personal.md` - Ruta relativa al home
- `#` al inicio del prompt - Añadir esa línea a memoria

### Ejemplo CLAUDE.md Global (`~/.claude/CLAUDE.md`)
```markdown
# Mis Preferencias Personales de Claude Code

## Estilo de Código
- Siempre usar TypeScript estricto
- Preferir functional components en React
- Usar 2 espacios para indentación
- Commits en español, código en inglés

## Herramientas Favoritas
- Tests: Jest + React Testing Library
- Linting: ESLint + Prettier
- Build: Vite para frontend, esbuild para librerías

## Comandos Personales Frecuentes
- `npm run dev` - Desarrollo
- `npm test -- --watch` - Tests en watch mode
- `npm run build && npm run preview` - Preview build

## Contexto Personal
@~/.claude/project-specific/current-focus.md
```

### Ejemplo CLAUDE.md Proyecto (`./CLAUDE.md`)
```markdown
# Proyecto E-Commerce - Guía de Desarrollo

## Arquitectura
- **Backend**: Node.js + Express + PostgreSQL
- **Frontend**: React + TypeScript + Tailwind CSS
- **Estado**: Zustand para estado global
- **Testing**: Jest + Cypress
- **Deploy**: Docker + AWS ECS

## Comandos del Proyecto
- `npm start` - Desarrollo completo (backend + frontend)
- `npm run test:all` - Todos los tests
- `npm run build:prod` - Build optimizado
- `docker-compose up` - Entorno local completo

## Convenciones Específicas
- Componentes en `src/components/ComponentName/`
- Cada componente tiene: `.tsx`, `.test.tsx`, `.stories.tsx`
- API endpoints siguen REST conventions
- DB migrations en `migrations/` con timestamp

## Configuración Específica del Equipo
@docs/development-setup.md
@docs/api-conventions.md
```

---

## 🤖 Subagentes Especializados

### Ubicación: `~/.claude/agents/*.md`

### Estructura de Subagente
```markdown
---
name: db-expert
description: Especialista en bases de datos para consultas SQL, optimización y análisis de esquemas. Usar proactivamente para cualquier tarea de BD.
tools: Bash, Read, Edit, mcp__postgres__query
---
Eres un DBA senior especializado en PostgreSQL y optimización de consultas.

### Tu Proceso de Trabajo
1. **Analizar petición** - Entender completamente el objetivo
2. **Examinar esquema** - Revisar estructura de tablas relevantes  
3. **Escribir consulta segura** - Priorizar seguridad y rendimiento
4. **Explicar solución** - Documentar decisiones importantes
5. **Optimizar si necesario** - Sugerir mejoras de rendimiento

### Especialidades
- Consultas complejas con JOINs y subconsultas
- Optimización de índices
- Análisis de planes de ejecución
- Migrations seguras
- Debugging de queries lentas
```

### Subagentes Útiles para Crear

**Backend Developer**
```markdown
---
name: backend-dev
description: Especialista en desarrollo backend, APIs REST/GraphQL, autenticación y arquitectura de servidor.
tools: Bash, Read, Edit, Write, Grep
---
```

**Frontend Expert**
```markdown
---
name: frontend-expert
description: Experto en React, TypeScript, estado global, optimización de rendimiento y UX/UI.
tools: Read, Edit, Write, Bash(npm *)
---
```

**DevOps Engineer**
```markdown
---
name: devops
description: Especialista en Docker, CI/CD, deployment, monitorización y troubleshooting de infraestructura.
tools: Bash, Read, Edit, Write
---
```

---

## 🎯 Comandos Personalizados (Slash Commands)

### Ubicación: `~/.claude/commands/*.md`

### Ejemplo: Crear Componente React
```markdown
---
description: Crea un componente React completo con test, storybook e index
argument-hint: [ComponentName]
allowed-tools:
  - Write
  - Edit
  - Bash(npm run lint:fix *)
---
# Crear Componente React: $ARGUMENTS

## Contexto del Proyecto
**Estructura actual**: !`find src/components -name "*.tsx" | head -5`
**Componente de referencia**: @src/components/Button/Button.tsx

## Tareas a Realizar
1. Crear `src/components/$ARGUMENTS/$ARGUMENTS.tsx`
2. Crear `src/components/$ARGUMENTS/$ARGUMENTS.test.tsx`
3. Crear `src/components/$ARGUMENTS/$ARGUMENTS.stories.tsx`
4. Crear `src/components/$ARGUMENTS/index.ts`
5. Seguir convenciones del proyecto
6. Ejecutar linter al final
```

### Ejemplo: Análisis de Performance
```markdown
---
description: Analiza el rendimiento del código y sugiere optimizaciones
argument-hint: [ruta-archivo-o-directorio]
allowed-tools:
  - Read
  - Bash
  - Grep
---
# Análisis de Performance: $ARGUMENTS

## Análisis Automático
**Bundle size**: !`npx webpack-bundle-analyzer build/static/js/*.js --analyze`
**Lighthouse**: !`lighthouse $ARGUMENTS --output=json | jq '.audits.performance.score'`

## Áreas a Revisar
1. **Re-renders innecesarios** en componentes React
2. **Imports pesados** no optimizados
3. **Consultas N+1** en base de datos
4. **Assets sin optimizar** (imágenes, fonts)
5. **JavaScript bundles** demasiado grandes
```

---

## 🛠️ CLI y Comandos

### Comandos Básicos
```bash
claude                    # Modo interactivo
claude "tarea"           # Tarea única y salir
claude -p "query"        # Query modo SDK (scripting)
claude -c                # Continuar conversación reciente  
claude -r                # Reanudar conversación específica
claude commit            # Auto-commit inteligente
```

### Flags Avanzados
```bash
claude --model claude-3-opus "tarea compleja"
claude --permission-mode plan "analiza sin cambiar nada"
claude --add-dir ~/shared-libs "incluir librerías compartidas"
claude --max-turns 10 "limitar iteraciones para control de costes"
claude --output-format json -p "query" > result.json
```

### Gestión de Configuración
```bash
claude config list                    # Ver toda la configuración activa
claude config get permissions.allow  # Ver setting específico
claude config set model claude-3-opus # Cambiar setting
claude config add permissions.allow "Bash(docker *)" # Añadir a lista
claude doctor                        # Diagnóstico instalación
```

### Gestión MCP
```bash
# Agregar servidores
claude mcp add --scope user server-name -- command args
claude mcp add --scope project local-db -- npx dbhub
claude mcp add --transport http api-server https://api.example.com

# Gestión
claude mcp list                      # Listar todos
claude mcp get server-name          # Detalles específicos
claude mcp remove server-name       # Eliminar servidor
claude mcp reset-project-choices    # Reset aprobaciones proyecto
```

### Slash Commands en Sesión
```bash
# Configuración
/config                  # Gestión configuración interactiva
/permissions             # Gestionar permisos herramientas
/memory                  # Editar CLAUDE.md
/mcp                     # Gestión MCP y autenticación

# Control sesión
/model                   # Cambiar modelo mid-conversación
/output-style            # Cambiar estilo respuesta
/add-dir                 # Añadir directorio al contexto
/compact                 # Reducir contexto (gestión costes)
/clear                   # Limpiar historial

# Herramientas
/vim                     # Modo edición Vim
/terminal-setup          # Configurar atajos (Shift+Enter)
/doctor                  # Diagnóstico salud
/help                    # Lista todos los comandos
```

---

## 🌍 Variables de Entorno

### Autenticación
```bash
ANTHROPIC_API_KEY="your-api-key"
ANTHROPIC_MODEL="claude-3-5-sonnet-20241022"
CLAUDE_CODE_API_KEY_HELPER_TTL_MS="3600000"
```

### Proveedores Cloud
```bash
# Amazon Bedrock
CLAUDE_CODE_USE_BEDROCK=1
AWS_BEARER_TOKEN_BEDROCK="bedrock-api-key"

# Google Vertex AI
CLAUDE_CODE_USE_VERTEX=1
VERTEX_REGION_CLAUDE_3_5_SONNET="us-central1"
```

### Performance y Límites
```bash
BASH_DEFAULT_TIMEOUT_MS="120000"
BASH_MAX_OUTPUT_LENGTH="30000"
CLAUDE_CODE_MAX_OUTPUT_TOKENS="8192"
MCP_TIMEOUT="10000"
```

### Telemetría (OpenTelemetry)
```bash
CLAUDE_CODE_ENABLE_TELEMETRY=1
OTEL_METRICS_EXPORTER="otlp"
OTEL_EXPORTER_OTLP_ENDPOINT="http://collector:4317"
OTEL_RESOURCE_ATTRIBUTES="team=backend,env=prod"
```

### Desactivar Funcionalidades
```bash
DISABLE_AUTOUPDATER=1
DISABLE_TELEMETRY=1
DISABLE_COST_WARNINGS=1
CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1  # Desactiva todo lo anterior
```

---

## 🚨 Troubleshooting

### Instalación
```bash
# Problemas permisos NPM
claude migrate-installer

# WSL específicos
npm config set os linux
npm install -g @anthropic-ai/claude-code --force --no-os-check

# Command not found
which claude
echo $PATH | grep claude
```

### Autenticación
```bash
/logout                              # En sesión interactiva
rm -rf ~/.config/claude-code/auth.json
claude                              # Re-autenticar
```

### Performance
```bash
/compact                            # Reducir contexto en sesión
/clear                              # Limpiar historial

# Optimizar .gitignore
echo -e "node_modules/\nbuild/\ndist/\n.cache/" >> .gitignore
```

### MCP Issues
```bash
claude mcp list                     # Ver estado servidores
claude --mcp-debug                 # Debug detallado MCP
claude mcp reset-project-choices   # Reset aprobaciones proyecto

# Verificar configuración global
cat ~/.claude.json | jq '.mcpServers'
```

### Permisos Issues
```bash
# Modo debug permisos
claude --permission-mode plan "analizar sin ejecutar"

# Ver permisos activos
/permissions                        # En sesión interactiva
claude config get permissions      # Via CLI
```

---

## 📚 Workflows Profesionales

### 🔍 Análisis de Codebase Nuevo
```markdown
1. **Overview General**
   > Give me a comprehensive overview of this codebase

2. **Arquitectura**
   > Explain the main architecture patterns and design decisions

3. **Setup y Dependencies**
   > What's the development setup process and key dependencies?

4. **Testing Strategy**
   > How is testing organized and what's the coverage?

5. **Deployment**
   > How is this project built and deployed?
```

### 🐛 Debug y Resolución de Issues
```markdown
1. **Reproducir Issue**
   > I'm seeing this error: [paste error]. Help me reproduce it

2. **Análisis de Root Cause**
   > Analyze the recent changes that might have caused this

3. **Investigación**
   > Check logs, tests, and related code for clues

4. **Solución**
   > Suggest 2-3 different approaches to fix this

5. **Prevention**
   > How can we prevent this type of issue in the future?
```

### 🔄 Refactoring Seguro
```markdown
1. **Análisis Pre-refactor**
   > Analyze this code for refactoring opportunities

2. **Plan de Refactor**
   > Create a step-by-step refactoring plan

3. **Tests de Protección**
   > Add comprehensive tests before refactoring

4. **Refactor Incremental**
   > Refactor in small, safe steps

5. **Validación Post-refactor**
   > Verify all functionality still works correctly
```

### 🚀 Feature Development
```markdown
1. **Requirement Analysis**
   > Help me understand and break down this feature requirement

2. **Design Decision**
   > What's the best approach for implementing this?

3. **Implementation Plan**
   > Create a detailed implementation plan

4. **Code Generation**
   > Implement the core functionality

5. **Testing & Documentation**
   > Add tests and update documentation
```

### 📊 Performance Optimization
```markdown
1. **Performance Audit**
   > Analyze this code/app for performance bottlenecks

2. **Metrics Baseline**
   > Establish current performance metrics

3. **Optimization Plan**
   > Prioritize optimizations by impact vs effort

4. **Implementation**
   > Implement optimizations incrementally

5. **Measurement**
   > Measure and verify performance improvements
```

---

## 🔗 Referencias Rápidas

### Documentación Oficial
- **Docs**: https://docs.anthropic.com/en/docs/claude-code/
- **CLI Reference**: https://docs.anthropic.com/en/docs/claude-code/cli-reference
- **MCP Protocol**: https://modelcontextprotocol.io/

### Repositorios
- **Claude Code**: https://github.com/anthropics/claude-code
- **MCP Servers**: https://github.com/modelcontextprotocol/servers

### Herramientas y Extensiones
- **VS Code Extension**: Búsqueda en marketplace
- **JetBrains Plugin**: Disponible en IDE settings
- **MCP Servers Populares**: Linear, Notion, GitHub, Jira, Slack

### URLs Documentación Oficial (para WebFetch)

#### Getting Started
- https://docs.anthropic.com/en/docs/claude-code/overview
- https://docs.anthropic.com/en/docs/claude-code/quickstart
- https://docs.anthropic.com/en/docs/claude-code/common-workflows

#### Build with Claude Code
- https://docs.anthropic.com/en/docs/claude-code/sdk
- https://docs.anthropic.com/en/docs/claude-code/sub-agents
- https://docs.anthropic.com/en/docs/claude-code/output-styles
- https://docs.anthropic.com/en/docs/claude-code/hooks-guide
- https://docs.anthropic.com/en/docs/claude-code/github-actions
- https://docs.anthropic.com/en/docs/claude-code/mcp
- https://docs.anthropic.com/en/docs/claude-code/troubleshooting

#### Deployment
- https://docs.anthropic.com/en/docs/claude-code/third-party-integrations
- https://docs.anthropic.com/en/docs/claude-code/amazon-bedrock
- https://docs.anthropic.com/en/docs/claude-code/corporate-proxy
- https://docs.anthropic.com/en/docs/claude-code/llm-gateway
- https://docs.anthropic.com/en/docs/claude-code/devcontainer

#### Administration
- https://docs.anthropic.com/en/docs/claude-code/setup
- https://docs.anthropic.com/en/docs/claude-code/iam
- https://docs.anthropic.com/en/docs/claude-code/security
- https://docs.anthropic.com/en/docs/claude-code/data-usage
- https://docs.anthropic.com/en/docs/claude-code/monitoring-usage
- https://docs.anthropic.com/en/docs/claude-code/costs
- https://docs.anthropic.com/en/docs/claude-code/analytics

#### Configuration
- https://docs.anthropic.com/en/docs/claude-code/settings
- https://docs.anthropic.com/en/docs/claude-code/ide-integrations
- https://docs.anthropic.com/en/docs/claude-code/terminal-config
- https://docs.anthropic.com/en/docs/claude-code/memory
- https://docs.anthropic.com/en/docs/claude-code/statusline

#### Reference
- https://docs.anthropic.com/en/docs/claude-code/cli-reference
- https://docs.anthropic.com/en/docs/claude-code/interactive-mode
- https://docs.anthropic.com/en/docs/claude-code/slash-commands
- https://docs.anthropic.com/en/docs/claude-code/hooks

#### Resources
- https://docs.anthropic.com/en/docs/claude-code/legal-and-compliance

---

## ⚡ Atajos y Tips Avanzados

### Atajos de Teclado
- `Shift + Enter` - Submit prompt (configurable con `/terminal-setup`)
- `Ctrl + C` - Cancelar operación actual
- `ESC` - Salir modo interactivo

### Tips de Productividad
```bash
# Alias útiles para .bashrc/.zshrc
alias cc="claude"
alias ccp="claude -p"
alias cccommit="claude commit"

# Función para análisis rápido
analyze() {
  claude "analyze this file: $1"
}

# Template de proyecto
claude "setup a new $1 project with best practices"
```

### Optimización de Costes
```bash
# Usar modelo más barato para tareas simples
claude --model claude-3-haiku "simple task"

# Limitar iteraciones
claude --max-turns 5 "complex task"

# Compactar contexto frecuentemente
/compact
```

### Integration con CI/CD
```bash
# En GitHub Actions
- name: Code Review
  run: claude -p "review this PR diff" < diff.txt

# Validación pre-commit
claude -p "check this code for issues" --output-format json
```

---

*Última actualización: $(date +%Y-%m-%d)*
*Versión: 3.0 - Estructura reorganizada y optimizada*