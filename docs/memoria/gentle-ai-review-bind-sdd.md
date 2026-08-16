---
name: gentle-ai-review-bind-sdd
description: "El deadlock de Gentle AI no era un bug: faltaba atar la revisión aprobada al change con review bind-sdd"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 37c724e9-e9a5-43a0-92bd-d84b54438879
  modified: 2026-08-12T20:34:23.580Z
---

El bloqueo de `sdd-status` que se reportó como defecto del runtime
(gentle-ai#2997) **no era un defecto**. Síntoma:

- `nextRecommended: resolve-review`
- `remediationState.required: false`
- blocked: *"bounded review transaction is missing"*

Faltaban dos pasos, ninguno un bug:

1. **No había candidato.** Con el árbol limpio no se puede abrir una revisión;
   `review status --next-transition` devuelve `stop`. Con cambios reales pasa a
   `execute` / `fresh_target_ready`.
2. **La revisión aprobada no estaba atada al change.** Terminar la revisión y
   tener recibo NO basta:

   ```
   gentle-ai review bind-sdd --cwd <repo> --change <change> \
     --lineage <lineage> --expected-binding-revision ""
   ```

   `--expected-binding-revision` va vacío en el primer atado; su valor vive en
   `binding_revision` de `gentle-ai sdd-attempt status`. Tras atar:
   `remediationState.required: true`, `reviewGate.result: allow`,
   `next: remediate`.

Trampas al ejecutar la cadena:

- El target caduca: cualquier cambio en el árbol entre `status` y `start` da
  `stale_target_identity`. Re-derivar justo antes.
- El revisor de Claude Code no tiene herramientas: hay que darle la evidencia
  nativa entre `GENTLE_AI_CLAUDE_REVIEW_CONTEXT` y su `_END`, con
  `--name-status`, `--numstat` y el parche verbatim por ruta con índice
  base-cero. Con prosa devuelve `inspection: incomplete`, y eso **no se
  captura**. `review advisory prompt --runtime claude-code` la renderiza ya.
- Formas de argumento distintas: `sdd-status` toma el change **posicional**;
  `sdd-attempt` exige `--change` y `--cwd`.

El gate de `sdd-attempt reset` sigue siendo decisión de mantenedor y nunca
automática — ver [[true-app-sdd-preflight]] y [[true-app-handoff-agosto-2026]].
