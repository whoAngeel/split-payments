# Matt Pocock Skills

Skills de [mattpocock/skills](https://github.com/mattpocock/skills) instaladas en este repo. Cada una se invoca como comando `/skill-name` en opencode.

| Skill | Installs | Qué hace | Cuándo usarla |
|---|---|---|---|
| `grill-me` | 355.9K | Entrevista implacable para afilar un plan o diseño. | Cuando tienes una idea de feature/arquitectura y quieres que el agente te haga preguntas duras para encontrar puntos ciegos antes de escribir código. |
| `grill-with-docs` | 288.5K | Igual que grill-me, pero además genera ADRs y glosario conforme avanza la conversación. | Cuando quieres el grilling Y que quede documentado automáticamente (ADRs, `CONTEXT.md`). Ideal para decisiones de diseño que deben persistir. |
| `improve-codebase-architecture` | 292.1K | Escanea el codebase buscando módulos superficiales, genera un reporte HTML visual con diagramas Mermaid (before/after), y luego hace grilling sobre el candidato que elijas. | Para refactors arquitectónicos: identificar módulos con mucha interfaz y poca profundidad, acoplamientos, o código difícil de testear. |
| `tdd` | 275.6K | Test-Driven Development: red-green-refactor con tracer bullets (vertical slices). Filosofía: testear comportamiento público, no implementación. | Feature nueva o bug fix donde quieras escribir tests primero. Usa `CONTEXT.md` para nombrar tests en el lenguaje del dominio. |
| `to-prd` | 256.7K | Convierte la conversación actual en un PRD (Product Requirements Document) y lo publica en el issue tracker. Sin entrevista extra: sintetiza lo ya discutido. | Al final de una discusión de feature, para formalizar lo acordado como spec antes de implementar. |
| `to-issues` | 245.9K | Rompe un plan/spec/PRD en issues independientes usando tracer bullets (vertical slices que atraviesan todas las capas). Los publica en el issue tracker. | Después de un PRD o diseño ya aprobado, para crear tareas granulares que un agente o dev puede tomar una a una. |
| `domain-modeling` | 17.7K | Construye y mantiene el modelo de dominio: glosario (`CONTEXT.md`), ADRs. Desafía términos fuzzy, inventa edge cases, cross-reference con el código. | Cuando necesitás definir o refinar el lenguaje ubicuo del proyecto. Usado internamente por `grill-with-docs`. |
| `grilling` | 18.4K | Entrevista implacable: una pregunta a la vez, caminando cada rama del árbol de diseño. | Core del grilling. Usado internamente por `grill-me` y `grill-with-docs`. |

## Flujo típico

```
1. /grill-with-docs   → discutir y afilar el diseño (genera ADRs + CONTEXT.md)
2. /to-prd            → sintetizar la conversación en un PRD formal
3. /to-issues         → romper el PRD en issues verticales
4. /tdd               → implementar cada issue test-first
```

Para refactors arquitectónicos:
```
/improve-codebase-architecture → escanear, elegir candidato, grilling → implementar
```
