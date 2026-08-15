# Traspaso — 15 de agosto de 2026

Estado en vuelo. Si retomás el proyecto, **leé esto y luego
`PROJECT_CONTEXT.md`**: aquí está lo que quedó a medias, allí lo que no cambia.

---

## Dónde está todo

| | |
|---|---|
| Rama | `main` |
| Desplegado | https://juanjodior.github.io/true_app/ · SHA `89cb790` · Pages run 31833902940 `success` |
| Tests | **477 en verde**, `flutter analyze` limpio |
| Ciclo `case-publication-detail` | **CERRADO Y ARCHIVADO** el 15 de agosto de 2026 |

El comportamiento desplegado está al día: desde `89cb790` no ha cambiado ni una
línea de `lib/`, `web/` ni `assets/` — sólo tests y documentación.

---

## No hay nada a medias

El ciclo cerró con `sdd-verify` en **PASS**, 0 CRITICAL, 0 bloqueos, **23/23
requisitos y 48/48 escenarios**. El archivo está en
`openspec/changes/archive/2026-08-15-case-publication-detail/` con su
`archive-report.md`, y las cuatro capacidades nuevas viven ya en
`openspec/specs/`:

- `case-editorial-chapters`
- `case-publication-route`
- `expanded-case-dossier`
- `published-case-directory`

Junto a las dos del ciclo anterior (`intake-responsive-layout`,
`responsive-breakpoints`). Seis en total.

**No hace falta arrancar nada para "terminar" nada.** Lo siguiente es empezar de
cero cuando el mantenedor quiera.

---

## Lo siguiente, cuando se quiera

**Las cinco entidades del diseño de Claude Design «Ficha de Caso»**: evidencias,
hipótesis con pro/contra, ficha técnica, etapas de investigación, y lo que se
sabe / sigue abierto. Más la arquitectura por pestañas.

Está delimitado por escrito en el `design.md` archivado, §10.1: este ciclo
construyó hacia ese diseño «sólo hasta donde llega el modelo de datos actual».
Cada entidad nueva necesita campo en el borrador, editor, persistencia,
exportación, decodificación y renderizado — el propio diseño lo estima en
«roughly the size of this whole cycle».

La infraestructura ya está puesta: ese ciclo **dependía de que
`CaseDossierContent` existiera primero**, y ahora existe. La página ampliada lo
compone con `DossierPresentation.expanded`. Las pestañas se decidieron
explícitamente para después, porque necesitan aserciones de alcance por pestaña
que las specs actuales no tienen.

---

## Deuda abierta, heredada del ciclo cerrado

Nada de esto bloquea. Todo está en el `archive-report.md` con detalle.

| Qué | Por qué sigue abierto |
|---|---|
| **Móvil compacto sin verificar en navegador** | La tarea 9.10 quedó **sin marcar a propósito**. `resize_window` no llega al viewport de Flutter (`window.innerWidth` se queda clavado). Sólo hay cobertura automática a 500 y 360px. **Es la misma clase de ceguera que ya costó dos veces**: pendiente de abrir el despliegue en un teléfono de verdad |
| **Dos clics no accionables contra el canvas** | El botón de directorio de la barra y el «Volver al archivo» de la ficha. Cubiertos por tests de widget. Ni verificados en navegador ni declarados rotos |
| **Unit 7 formalmente reabierta** | La regla 9.12 decía que la Unit 9 no tocaría código. Lo tocó, porque la verificación en navegador encontró que ningún enlace directo funcionaba |
| **Unit 7 excedió el techo** | 1.566 líneas contra 1.500. Declarado con el motivo por el que no se podía partir más |
| **`createDraft` puede colisionar ids** | Deriva el id de `DateTime.now().millisecondsSinceEpoch`. Dos creaciones en el mismo milisegundo comparten `draftId`. Real, fuera de alcance, candidato a ciclo propio |

---

## Lo que este ciclo enseñó, y no conviene reaprender

**Tres defectos de producción. Ninguno lo cazó la suite de tests.**

1. El mapa reventaba con cualquier enlace directo (`onMapReady` se dispara
   offstage). Lo cazó un test que monta la app entera.
2. Ningún enlace directo funcionaba en el build (`initialLocation` pisaba la
   barra de direcciones). Lo cazó abrir Chrome. **El parámetro añadido para
   poder testear era exactamente lo que tapaba el fallo.**
3. La barra superior ya desbordaba en varias bandas. Se curó de rebote.

**Y `sdd-verify` devolvió FAIL con 3 CRITICAL en su primera pasada** — todos de
calidad de evidencia, todos de la misma familia que el defecto que este ciclo
existía para erradicar: `position.jumpTo` saltándose la física del scroll, un
ancho de escritorio sin probar, y media aserción que demostraba que el contenido
existía pero nunca que se alcanzara. Corregido sólo en tests, y **probado con
sondas de mutación que el verificador reprodujo por su cuenta**.

De ahí la disciplina que conviene mantener: **cada unidad lleva sus sondas
registradas**, y una revisión independiente vale más que cualquier suite verde.
Una suite verde es exactamente lo que también produce un scroll muerto.

Las trampas técnicas concretas están todas en `PROJECT_CONTEXT.md`, sección
«Trampas conocidas». Leerla antes de escribir el primer test ahorra un día.

---

## Convenciones que no se negocian

- Commits en castellano, convencionales, **sin atribución a IA**.
- Comentarios de código en castellano, explicando el porqué.
- Interfaz en castellano.
- Un `expect` por test: dos abortan en el primero y esconden el segundo.
- **Nunca `jumpTo`, `ensureVisible` ni `scrollUntilVisible` como prueba de
  alcance.** Gesto real con `dragFrom`, con precondición de no-vacuidad.
- Techo de 1500 líneas por unidad. Si se pasa, se declara.
