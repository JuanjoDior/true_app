---
name: true-app-handoff-agosto-2026
description: Dónde retomar true_app y qué leer antes de tocar nada; el estado en vuelo vive en HANDOFF.md del repo
metadata: 
  node_type: memory
  type: project
  originSessionId: 37c724e9-e9a5-43a0-92bd-d84b54438879
  modified: 2026-08-15T16:25:05.200Z
---

El estado en vuelo de true_app vive en **`HANDOFF.md`** en la raíz del repo, y lo
que no cambia en **`PROJECT_CONTEXT.md`**. Leer los dos, en ese orden, antes de
tocar nada. El usuario va rotando de asistente (Claude Code, OpenCode, Pi), así
que el traspaso tiene que estar en el repo y no sólo en la memoria de un agente.

**Al 15 de agosto de 2026: no hay nada a medias.** El ciclo SDD
`case-publication-detail` está CERRADO Y ARCHIVADO — `sdd-verify` en PASS con 0
CRITICAL, 23/23 requisitos y 48/48 escenarios. 477 tests en verde, desplegado en
https://juanjodior.github.io/true_app/ (SHA `89cb790`; desde entonces sólo han
cambiado tests y documentación). `openspec/specs/` tiene ya seis capacidades.

Lo siguiente **no es terminar nada**, es empezar: el ciclo de las cinco entidades
del diseño de Claude Design «Ficha de Caso» — evidencias, hipótesis, ficha
técnica, estado de investigación, y lo que se sabe / sigue abierto — con pestañas
de IA. Delimitado por escrito en el `design.md` archivado, §10.1.

Deuda abierta heredada, ninguna bloqueante y toda declarada en el
`archive-report.md`: el móvil compacto sin verificar en navegador (tarea 9.10
deliberadamente sin marcar), dos clics no accionables contra el canvas de
Flutter, la Unit 7 reabierta por la regla 9.12, su exceso de 1.566 líneas sobre
el techo de 1.500, y la colisión de `draftId` en `createDraft`.

Ver [[true-app-tests-verdes-no-prueban]] antes de escribir el primer test,
[[true-app-sdd-preflight]] para el preflight del SDD y
[[gentle-ai-review-bind-sdd]] si el gate se atasca.
