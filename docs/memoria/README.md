# Memoria del proyecto

Copia de las memorias que los asistentes van acumulando sobre true_app, puesta
en el repo **a propósito**.

## Por qué está aquí

La memoria de un asistente vive en la máquina donde se generó. Cambiar de
ordenador, de herramienta o de asistente la deja atrás, y con ella los hallazgos
que costaron días. Este proyecto ya ha rotado entre Claude Code, OpenCode y Pi.

En agosto de 2026 se comprobó además que la sincronización de memoria puede
fallar en silencio: 21 observaciones quedaron atascadas sin poder replicarse
porque les faltaba un campo obligatorio. **Nadie se entera hasta que las busca y
no están.**

El repo, en cambio, viaja siempre y no se pierde. Así que aquí van.

## Qué leer antes de tocar código

En este orden:

1. **`HANDOFF.md`** (raíz) — el estado en vuelo: qué se acaba de hacer, qué
   quedó abierto, qué es lo siguiente.
2. **`PROJECT_CONTEXT.md`** (raíz) — lo que no cambia: arquitectura,
   decisiones de producto, convenciones y la sección **Trampas conocidas**, que
   ahorra un día de trabajo a quien la lea.
3. Esta carpeta, si hace falta el detalle de algún hallazgo concreto.

## Qué hay

| Fichero | Qué cuenta |
|---|---|
| `MEMORY.md` | Índice de una línea por memoria |
| `true-app-handoff-agosto-2026.md` | Dónde retomar y qué leer primero |
| `true-app-tests-verdes-no-prueban.md` | Los tres defectos de producción que 472 tests no vieron |
| `true-app-tests-no-ven-el-navegador.md` | Por qué ningún widget test ve el navegador, y lo que costó |
| `flutter-scrolluntilvisible-no-prueba-scroll.md` | El helper que pasa en verde con el scroll muerto |
| `true-app-sdd-preflight.md` | Configuración del ciclo SDD y el gate del ledger |
| `gentle-ai-review-bind-sdd.md` | El "deadlock" que no era tal |

## Mantenimiento

No es una copia automática. Cuando aparezca un hallazgo que valga la pena
conservar, actualizar el fichero correspondiente **y** `PROJECT_CONTEXT.md`, que
es el que de verdad se lee. Una memoria que sólo vive en la herramienta se
pierde en el siguiente cambio de máquina.
