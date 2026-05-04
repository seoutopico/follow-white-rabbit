# Claude Code y Sistemas de Agentes

## Scope

Novedades técnicas y prácticas alrededor de Claude Code (la CLI de Anthropic) y la construcción de sistemas de agentes en general.

- Releases de Claude Code: features nuevas, hooks, slash commands, MCP servers, settings, integraciones IDE
- Claude Agent SDK: patrones para construir agentes propios, ejemplos reales
- Workflows multi-agente: orquestación, sub-agentes, paralelización, hand-off de contexto
- MCP (Model Context Protocol): servidores nuevos, casos de uso, integraciones útiles
- Comparativas con otras herramientas de coding agents (Cursor, Aider, Codex, etc.) cuando aporten información técnica
- Tips concretos: prompts efectivos, hooks útiles, configuraciones que escalan
- Bugs/limitaciones conocidas y workarounds documentados

## Skip

- Anuncios de marketing sin sustancia técnica
- Tweets virales sin código ni demostración
- Opiniones genéricas tipo "AI coding está cambiando todo"
- Tutoriales 101 muy básicos (instalar claude code, primer prompt)
- Noticias corporativas (rondas de financiación, contrataciones)

## Research Strategy

1. Revisar el changelog y docs oficiales de Claude Code: https://docs.claude.com/en/docs/claude-code
2. Buscar en GitHub repos con `claude-code` o agentes interesantes (>100 stars, actividad reciente)
3. Buscar en Hacker News, /r/ClaudeAI, Anthropic blog
4. Para MCP servers, revisar https://github.com/modelcontextprotocol y registries comunitarios
5. Cross-referencia: si un autor afirma X, busca el código o doc oficial que lo respalde
6. Las búsquedas pueden ser en cualquier idioma; la entrada final siempre en español

## Writing Style

**Target: 600-800 palabras por entrada.**

Escribe en español como un colega senior explicando algo útil que descubrió esta semana.

- **Estructura**: contexto del problema → qué cambió o qué hace falta → cómo se aplica → ejemplo concreto (con bloque de código si aplica) → trade-offs / qué vigilar después
- **Concreción**: comandos, nombres de hooks, rutas de archivos, snippets reales — no descripciones genéricas
- **Útil para alguien que ya usa Claude Code**: asume nivel intermedio, no expliques qué es la CLI
- **Cierra con**: preguntas abiertas, qué probar, o qué seguir cuando salga la siguiente versión
- Términos técnicos en inglés se quedan en inglés (hooks, slash commands, prompt, agent) si así son más claros
