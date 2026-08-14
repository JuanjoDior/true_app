# Traspaso — 14 de agosto de 2026

Estado en vuelo. Si retomás el proyecto, **leé esto y luego
`PROJECT_CONTEXT.md`**: aquí está lo que quedó a medias, allí lo que no cambia.

---

## Dónde está todo

| | |
|---|---|
| Rama | `main`, limpia y publicada |
| Último commit | `56f6ec3` |
| Desplegado | https://juanjodior.github.io/true_app/ · SHA `89cb790` · Pages run 31833902940 `success` |
| Tests | **472 en verde**, `flutter analyze` limpio |
| Ciclo SDD | `case-publication-detail` — **implementado y desplegado, SIN ARCHIVAR** |

---

## Lo primero que hay que hacer

**Archivar el ciclo `case-publication-detail`.** Está completo y en producción,
pero el change sigue abierto en `openspec/changes/`. Antes de abrir nada nuevo,
cerrar éste.

Dos cosas que el archive tiene que tener en cuenta y no puede pasar por alto:

1. **La Unit 7 está formalmente REABIERTA.** La regla 9.12 decía que la Unit 9 no
   tocaría código fuente. Lo tocó: la verificación en navegador encontró que
   ningún enlace directo funcionaba y hubo que arreglarlo (`89cb790`). Por su
   propia regla, eso reabre la unidad que lo introdujo. Está declarado en
   `tasks.md`; no lo tapes al archivar.
2. **Dos lagunas de verificación declaradas, no fabricadas.** El layout compacto
   no se verificó en navegador, y dos clics contra el canvas de Flutter no se
   pudieron accionar por coordenada. Están cubiertos por tests de widget y NO se
   afirman como probados en navegador. Tampoco se afirman rotos.

Si el gate de Gentle AI se atasca: el "deadlock" de agosto **no era un bug**.
Hace falta (a) un candidato que revisar y (b) `gentle-ai review bind-sdd`.

---

## Qué se entregó en este ciclo

Nueve unidades, once commits, de `e1e350d` a `56f6ec3`.

- **Capítulos editoriales**: cuatro tipos fijos y opcionales (Antecedentes, Los
  hechos, La investigación, Estado actual), con códec tolerante, exportación e
  ida y vuelta hasta el caso publicado. Séptima sección del formulario, detrás de
  Fotografías, sin botones de añadir ni reordenar — el orden es contrato.
- **Un solo renderizador de expediente**: `CaseDossierContent`, sin estado, que
  usan el panel compacto, la previsualización y la página ampliada. `CaseDossierPanel`
  pasó de 636 líneas a 34.
- **Rutas hash públicas**: cada caso en `/#/casos/<slug>`, compartible y
  recargable. Historial correcto, slug desconocido con hash conservado.
- **Directorio del archivo**: todo lo publicado, año descendente, alcanzable en
  las tres topologías.
- **Persistencia serializada** de borradores: una escritura vieja ya no pisa a una
  nueva.

---

## Lo siguiente, cuando se archive

El ciclo nuevo que el mantenedor ya tiene decidido: **las cinco entidades del
diseño de Claude Design "Ficha de Caso"** — evidencias, hipótesis, ficha técnica,
estado de investigación, y lo que se sabe / sigue abierto — más las pestañas de
IA. La página ampliada (`case_detail_page.dart`) ya está construida para
recibirlas: compone `CaseDossierContent` con `DossierPresentation.expanded` y le
pone su propia caja y ancho de lectura.

Corrección de premisa importante, del propio mantenedor: **la página ampliada NO
es un espejo del panel compacto.** Es un superconjunto. La regla es "no duplicar
renderizador", no "mismo contenido".

---

## Lo que este ciclo enseñó, y no conviene reaprender

**Tres defectos de producción. Ninguno lo cazó la suite de tests.**

1. El mapa reventaba con cualquier enlace directo (`onMapReady` se dispara
   offstage). Lo cazó un test que monta la app entera.
2. Ningún enlace directo funcionaba en el build (`initialLocation` pisaba la
   barra de direcciones). Lo cazó abrir Chrome.
3. La barra superior ya desbordaba en varias bandas. Se curó de rebote.

**Y dos tests míos que no podían fallar**, cazados por mutación — uno de ellos
escrito precisamente creyendo que cazaba el defecto firma del proyecto.

De ahí la disciplina que sigue este repo y que conviene mantener: **cada unidad
lleva sus sondas de mutación registradas en `tasks.md`**, con qué mató cada una.
No es ceremonia. Una red que no has visto romperse no sabés si sostiene algo.

Las trampas técnicas concretas están todas en `PROJECT_CONTEXT.md`, sección
"Trampas conocidas". Leerla antes de escribir el primer test ahorra un día.

---

## Convenciones que no se negocian

- Commits en castellano, convencionales, **sin atribución a IA**.
- Comentarios de código en castellano, explicando el porqué.
- Interfaz en castellano.
- Un `expect` por test: dos abortan en el primero y esconden el segundo.
- Techo de 1500 líneas por unidad. Si se pasa, se declara — la Unit 7 llegó a
  1.566 y está escrito por qué no se podía partir más.
