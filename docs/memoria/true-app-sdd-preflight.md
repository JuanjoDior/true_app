---
name: true-app-sdd-preflight
description: Preflight SDD que el usuario eligió para true_app y el gate de reset del ledger que bloquea cada verificación nueva
metadata: 
  node_type: memory
  type: project
  originSessionId: 18c09f95-7afd-469f-b576-a604d54459fe
  modified: 2026-08-12T09:38:36.925Z
---

Preflight SDD elegido por el usuario para `true_app` (12 de agosto de 2026):
modo de ejecución **auto**, artefactos **hybrid** (archivos OpenSpec
autoritativos + Engram), entrega **single-pr**, presupuesto de revisión
**1000 líneas** (lo escribió a mano en vez de elegir 400 u 800).

Este repo entrega con **commits directos a `main`**, sin flujo de PRs. El
deploy a GitHub Pages se dispara con el push.

**Gate que sorprende y hay que anticipar:** cada `sdd-verify` nuevo necesita un
objetivo nuevo en el ledger de runtime, y un objetivo nuevo exige
`gentle-ai sdd-attempt reset`, que es una **decisión explícita de mantenedor y
nunca automática**. Cambiar el `--work-unit` o el `--evidence-goal` ya cuenta
como objetivo distinto y devuelve `blocked: maintainer_decision`. En una sola
sesión hicieron falta dos resets.

La tentación es reusar la etiqueta de work-unit anterior para pasar el gate sin
preguntar. **No hacerlo**: falsea la evidencia, que es justo lo que estos
ciclos existen para evitar. Hay que parar y pedirle la decisión al usuario, con
la contabilidad de `gentle-ai sdd-attempt status` delante para que decida
informado.

Ver también [[true-app-handoff-agosto-2026]].
