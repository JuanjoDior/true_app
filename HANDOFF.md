# Traspaso — 12 de agosto de 2026

Documento de continuidad entre sesiones. Quien llegue aquí puede retomar sin
arqueología. Cuando el ciclo `intake-responsive` esté archivado, este archivo se
borra.

Contexto de producto y convenciones: `PROJECT_CONTEXT.md`. Este documento sólo
cubre el estado en vuelo.

---

## 1. Comprobado en un teléfono real

**Hecho.** El mantenedor abrió `https://juanjodior.github.io/true_app/` desde un
móvil real el 12 de agosto de 2026 y confirmó que **las dos pantallas**
funcionan: el formulario de alta y la Sala de Situación pública.

Eso importa más de lo que parece. Era la única evidencia capaz de cerrar el
agujero que ningún widget test podía observar (§2): confirma que el arreglo del
viewport es real en producción, no sólo en la suite.

Dos apuntes que quedan como registro, no como pendientes:

- **Zoom al enfocar un campo.** Se omitieron `maximum-scale`/`user-scalable=no`
  a propósito (bloquear el pinch-zoom es una regresión WCAG 1.4.4). El coste
  aceptado es que iOS puede hacer zoom al enfocar un campo de texto. Si algún
  día molesta, la salida NO es bloquear el zoom: es subir el `font-size` de los
  campos.
- **El desplegable de categoría y los chips de campo.** En las capturas del bug
  salían apelotonados. La hipótesis era que fueran síntomas de la rama de
  escritorio activa en móvil. En la comprobación real no se reportó
  apelotonamiento, así que la hipótesis queda **sin refutar** — que no es lo
  mismo que medida.

---

## 2. Qué se encontró y qué se arregló

### La causa raíz

`web/index.html` nunca declaró `<meta name="viewport">` — el único commit que
había tocado el archivo era el `72f8d28` inicial. Sin ese meta, el navegador
móvil cae a un viewport de ancho de escritorio (~980px CSS), así que
`MediaQuery.sizeOf(context).width` salía por encima de los umbrales y **todas**
las pantallas con gate de ancho elegían su rama ancha dentro de una pantalla de
390px.

`flutter build web` copia ese archivo tal cual a `build/web` y el workflow de
Pages lo publica, así que el defecto llegaba entero a producción.

Confirmado desde las capturas por el texto *"Crea o selecciona un borrador para
editarlo"*, que sólo existe en la rama de escritorio
(`intake_workspace_screen.dart:68`), y porque la lista de borradores ocupaba
~66% de una pantalla de 390px: el `SizedBox(width: 260)` de escritorio a 1:1.

### El alcance real, que era mayor

**Nunca fue un problema del formulario.** `home_page.dart:30` decide la Sala
pública con `width >= Breakpoints.sidePanel` (880). Con el viewport en ~980,
980 ≥ 880, así que **la Sala pública también le servía `_DesktopBody` encogido
a todo visitante de móvil**. El arreglo los movió a `_MobileBody` a 1:1.

Eso es un cambio de comportamiento visible en una pantalla publicada, y es el
riesgo número uno del `proposal.md` disparándose por una vía que la tabla de
riesgos no contemplaba. El criterio de éxito que afirmaba que la Sala se
comportaba igual que antes quedó **sin tildar y tachado**, con la corrección
escrita al lado. No se reescribió para que resultara cierto — y la
verificación dictó explícitamente que un criterio así **no** bloquea el archive.

### La lección, que es lo que de verdad hay que llevarse

165 tests responsive, verificados por mutación, tres rondas de verificación. Y
el feature no funcionaba en un teléfono.

Ningún widget test podía verlo: `tester.view.physicalSize` inyecta el tamaño y
salta por encima de la negociación de viewport del navegador. No había ninguna
capa que tocara un navegador real. **No fue un fallo de disciplina; fue un
agujero en la pirámide de tests.** Y el cierre vino de donde tenía que venir: de
un teléfono, no de un test.

Y no es la primera vez: `PROJECT_CONTEXT.md` ya registraba que el bug más caro
del proyecto pasó por delante de 45 tests en verde y apareció usando la app de
verdad en el navegador. Dos veces el mismo patrón.

Las cuatro verificaciones del ciclo encontraron el mismo tipo de defecto cuatro
veces: **una aserción que no podía fallar**. Está detallado en
`PROJECT_CONTEXT.md` → "Trampas conocidas".

---

## 3. Estado del ciclo SDD `intake-responsive`

**Abierto.** La fase 9 está verificada; queda un blocker distinto.

| Fase | Qué | Estado |
|------|-----|--------|
| 1–4 | Breakpoints compartidos, fallbacks de filas, rama estrecha, limpieza de viewport en tests | Verificadas |
| 5–6 | Cobertura de escritorio, ajuste fino, umbrales fijados por igualdad | Verificadas |
| 7 | `<meta name="viewport">` + guard `test/web_index_viewport_test.dart` | Verificada |
| 8 | Requisito "Host Document Viewport Precondition" + corrección del proposal | Verificada |
| 9 | Quitado el escenario infalsable + grafía `user-scalable=0` + aserciones separadas | Verificada (generación 8) |

La verificación de generación 8 (`verify-report.md`, evidence
`sha256:dbe736ab…`) cerró la fase 9: el escenario infalsable ya no está en la
especificación, y las mutaciones de `user-scalable=no` y `user-scalable=0` hacen
fallar el guard **por separado**. `flutter test` → 169 verdes. `flutter analyze`
→ limpio. Cobertura agregada 88.51%.

Pero el veredicto sigue siendo `fail` con `blockers: 1`, y ahora por otra razón:

> El escenario **"All six sections reachable at 360px"** no tiene ninguna prueba
> runtime a nivel de workspace. `intake_narrow_layout_test.dart` monta a 360px
> pero no recorre las seis secciones; `intake_form_widget_test.dart` itera
> `kCaseFormSections` en otro harness. La evidencia estática del registro no
> satisface un escenario que dice *"WHEN the user scrolls the form"*.

Ése es el único blocker para archivar.

### Cómo desbloquearlo

El reset de mantenedor a generación 8 **ya se hizo**. No hay que repetirlo, ni
reutilizar la etiqueta de work-unit anterior para colarse. El intento de
generación 8 quedó settled como `failed` y devolvió `state: proceed`.

Lo que falta es la prueba, RED primero:

1. Añadir a `test/intake_narrow_layout_test.dart` un test que monte el workspace
   a 360px, haga scroll y afirme las seis secciones de `kCaseFormSections`, en
   el mismo orden que en escritorio.
2. **Verlo fallar antes** de que exista lo que lo pone en verde. Un test que no
   se vio fallar no prueba nada (`PROJECT_CONTEXT.md` → "Trampas conocidas").
3. Re-verificar con la contabilidad nativa hasta `blockers: 0`, y entonces
   `sdd-archive`.

**Y hay un obstáculo antes de eso.** El runtime de Gentle AI 2.3.0 quedó en
deadlock: `sdd-status` devuelve `nextRecommended: resolve-review` y
`remediationState.required: false`, pero rechaza con `verify evidence cannot
enter remediation: blockers must be zero for archive readiness; bounded review
transaction is missing`. No hay transición ejecutable. Se reportó como
ocurrencia con diagnóstico sanitizado en
[gentle-ai#2997](https://github.com/Gentleman-Programming/gentle-ai/issues/2997#issuecomment-5265732499).
El lifecycle no se reanuda hasta que haya una corrección publicada instalada, o
una recuperación nativa documentada y autorizada. **Nada de inventar un PASS ni
saltarse el gate.**

Con `blockers: 0`, toca `sdd-archive`. Eso vuelca las specs delta a
`openspec/specs/`, que **está vacío**: este ciclo lo arranca, así que lo que se
archive queda como registro permanente.

### Preflight de sesión SDD que se usó

`auto` · artefactos `hybrid` (archivos OpenSpec autoritativos + Engram) ·
entrega `single-pr` (este repo commitea directo a `main`, sin flujo de PRs) ·
presupuesto de revisión 1000 líneas.

---

## 4. Errores y huecos pendientes

Ordenados por lo que costaría descubrirlos tarde.

| # | Qué | Dónde | Nota |
|---|-----|-------|------|
| 1 | Ciclo SDD abierto | `openspec/changes/intake-responsive/` | Sección 3. Un blocker y un runtime en deadlock |
| 2 | Banda 1024–1199px | `intake_workspace_screen.dart` | La columna del formulario es `ancho - 260 - 380 - 40`, así que sólo llega a `formRowStack` (520) a partir de 1200. En toda esa banda **todas** las filas se apilan en pantallas de escritorio. Anticipado en `design.md:9`, ausente del proposal, sin test: `intake_desktop_layout_test.dart` sólo monta a 1440 |
| 3 | `SituationTopBar` desborda | `situation_top_bar.dart` | Bandas medidas: 980 (21px) y 1030–1080 (59→9px). Preexistente, fijado como está en `situation_breakpoints_test.dart`. Candidato a change propio |
| 4 | No hay capa de navegador real | `test/` | El guard del viewport tapa el agujero concreto, no la familia. Un E2E mínimo (Playwright) sobre el build web cerraría la clase entera |
| 5 | 260 y 380 son literales mágicos | `intake_workspace_screen.dart:58,250` | Deberían ser tokens en `lib/core/layout/breakpoints.dart`. El test los redeclara, lo que hoy funciona como red pero duplica la verdad |
| 6 | "Las seis secciones alcanzables a 360px" | `test/intake_narrow_layout_test.dart` | Sólo evidenciado estáticamente. Es el blocker de la sección 3 |
| 7 | `isExpanded: true` en desplegables | `basic_data_section.dart:46,84` | Cambio cosmético en escritorio, sin test. Conocido y aceptado |
| 8 | Error en consola al arrancar | `updates_ticker.dart:46` | Preexistente, sin efecto visible |

---

## 5. Hacia dónde va esto

Lo que el mantenedor quiere a continuación, en sus términos: **dejar el
formulario listo en todas las plataformas que se van a usar, con la vista
puesta en la publicación — cómo se muestra el caso en detalle y la pantalla del
caso en sí.**

Eso no está especificado todavía. No hay proposal, ni spec, ni diseño. **Lo
correcto es explorar antes de escribir código**, y hay una pieza que condiciona
todo lo demás:

> `CaseDossierPanel` pinta el expediente **y lo reutiliza la previsualización
> del formulario**. Si el preview necesita mostrar algo nuevo, la primera
> pregunta es si el expediente publicado debería mostrarlo también. Casi
> siempre la respuesta es sí, y entonces sale gratis en los dos sitios.
> — `PROJECT_CONTEXT.md`

Preguntas abiertas que conviene resolver con el mantenedor antes de proponer
nada, no después:

- **Qué plataformas** son "todas las que vamos a usar". ¿Web móvil y escritorio
  y ya, o entra iOS/Android nativo? Cambia el alcance por completo.
- **Qué es "el caso en detalle"** frente a lo que `CaseDossierPanel` ya pinta.
  ¿Una pantalla propia con su ruta, o el panel actual crecido?
- **Si el expediente necesita URL propia.** Hoy la navegación es el mapa y no
  hay rutas por caso. Compartir un caso concreto es imposible, y para un
  producto editorial público eso pesa.
- **`featuredRank` y `relevanceRank`**, que deciden qué caso sale destacado y en
  qué orden. Hoy se editan a mano en el asset y el formulario no los captura.
  Si la publicación entra en alcance, esto entra con ella.

El circuito de publicación actual es manual a propósito (`PROJECT_CONTEXT.md` →
"El circuito de publicación"). La decisión de automatizarlo tiene un disparador
escrito: cuando llegue un lote de diez casos de golpe. Conviene no rebasarlo sin
nombrarlo.

---

## 6. Commits de esta sesión

| Commit | Qué | Remoto |
|--------|-----|--------|
| `de88087` | `fix: la web adopta el ancho del dispositivo en el móvil` | pusheado, desplegado |
| `401ed03` | `docs: registra la fase del viewport en el change de intake` | pusheado, desplegado |
| `3af24d7` | `docs: verifica el change tras las fases del viewport y los umbrales` | pusheado |
| `4e59ef4` | `docs: especifica la precondición del documento anfitrión` | pusheado |
| `3710df8` | `docs: quita el escenario que no podía fallar` | **sin pushear** |
| `061dcba` | `docs: deja el traspaso escrito para la próxima sesión` | **sin pushear** |
