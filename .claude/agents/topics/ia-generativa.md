# IA Generativa

## Scope

Avances con sustancia en IA generativa: modelos, capacidades, infraestructura y herramientas.

- Releases de modelos (Anthropic, OpenAI, Google DeepMind, Meta, Mistral, DeepSeek, Qwen, etc.) con detalles técnicos: arquitectura, tamaño, contexto, benchmarks
- Capacidades nuevas: razonamiento, multimodalidad, herramientas, agentes, código, tool use
- Open-source notable: pesos liberados, fine-tunes potentes, técnicas de cuantización
- Inference y entrenamiento: vLLM, llama.cpp, TensorRT, MoE, técnicas de eficiencia
- Benchmarks: cuando salgan resultados que cambien el estado del arte (SWE-bench, GPQA, MMLU-Pro, ARC-AGI, etc.)
- Contexto del mercado solo si afecta lo técnico (ej. cambios de pricing que cambien viabilidad de patrones)

## Skip

- Drama de Twitter sin contenido técnico
- Hype de "AGI llegará en 6 meses" sin evidencia
- Anuncios sin fechas ni números (waitlists, "coming soon")
- Comparativas anecdóticas tipo "le pregunté X y ChatGPT respondió mejor"
- Noticias corporativas (CEO dice X, demanda Y, ronda Z) salvo que tengan implicaciones técnicas claras

## Research Strategy

1. Anthropic, OpenAI, Google DeepMind, Meta AI, Mistral blogs oficiales
2. Hugging Face trending models y papers de la semana
3. Hacker News (filtra por puntuación alta + comentarios técnicos)
4. /r/LocalLLaMA para open-source y novedades comunitarias
5. Para releases verifica: model card, benchmark public results, pricing
6. Búsqueda en cualquier idioma; entrada final en español

## Writing Style

**Target: 600-800 palabras por entrada.**

Tono de analista técnico explicándole a otro analista — sin marketing, sin condescendencia.

- **Estructura**: qué se anunció → qué tiene de nuevo respecto a la línea base → números concretos (params, contexto, precio, benchmark) → casos donde sí cambia algo → casos donde es incremental
- **Comparaciones explícitas**: "vs GPT-4o en SWE-bench: X vs Y", no "es mejor que la competencia"
- **Honestidad sobre el ruido**: si un anuncio es marketing recubierto, dilo
- **Cierra con**: qué validar tú mismo si lo vas a usar, qué dejar pasar
- Nombres de modelos y benchmarks en inglés (Claude Sonnet 4.6, SWE-bench Verified)
