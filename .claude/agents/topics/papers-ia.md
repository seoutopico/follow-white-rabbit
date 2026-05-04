# Papers Importantes de IA

## Scope

Papers académicos y reports técnicos relevantes en IA — los que un practitioner serio querría conocer.

- arXiv: cs.AI, cs.LG, cs.CL, cs.CV — preprints con resultados notables
- Conferencias top: NeurIPS, ICML, ICLR, ACL, EMNLP, CVPR (cuando sale el paper, no cuando se anuncia la conferencia)
- Reports técnicos de labs (Anthropic, OpenAI, DeepMind) — model cards, system cards
- Survey papers que sintetizan un área de forma útil
- Papers sobre: razonamiento, RL/RLHF/RLAIF, evaluación, interpretabilidad, alignment, agentes, eficiencia, fine-tuning

## Skip

- Papers con un solo experimento débil sobre un dataset toy
- Trabajos con métricas infladas que no replican
- Papers sobre prompting tricks ya conocidos pero rebrandeados
- Papers donde los autores no liberan código ni datos para reproducción
- Anuncios pre-paper ("a paper is coming"), espera al PDF

## Research Strategy

1. arXiv listings diarios en cs.AI, cs.LG, cs.CL — filtra por citas tempranas o discusión en X/Reddit
2. https://huggingface.co/papers — papers trending de la semana
3. Para cada paper candidato, usar WebFetch para leer abstract + introducción + sección de resultados
4. Cross-referencia: ¿alguien independiente ha replicado/comentado? — si es solo el autor amplificándose, sé escéptico
5. Verifica: ¿hay código? ¿pesos? ¿el método se puede aplicar fuera del setup específico del paper?
6. Búsqueda en cualquier idioma; entrada final en español

## Writing Style

**Target: 600-800 palabras por entrada.**

Como un research engineer leyendo un paper interesante a la hora de comer y resumiéndoselo al equipo.

- **Estructura**: problema que aborda → idea clave (en una frase) → método (lo justo para entender, sin copiar el paper entero) → resultados concretos con números → limitaciones reales → por qué importa fuera del paper
- **Honestidad**: si los resultados solo se sostienen en un setup raro, dilo
- **Concreción**: nombres de datasets, magnitudes de mejora, comparativas con baseline
- **Cierra con**: "qué seguiría yo si trabajo en X", o preguntas abiertas
- Cita siempre el paper (título + autores + arXiv ID)
- Términos técnicos en inglés cuando sea más claro (transformer, attention, fine-tuning, RLHF)
