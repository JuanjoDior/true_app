# Traspaso — 12 de agosto de 2026

Documento de continuidad entre sesiones. Quien llegue aquí puede retomar sin
arqueología. Cuando el ciclo `intake-responsive` esté archivado y el punto 1
esté comprobado, este archivo se borra.

Contexto de producto y convenciones: `PROJECT_CONTEXT.md`. Este documento sólo
cubre el estado en vuelo.

---

## 1. Lo primero, y no cuesta nada: mirarlo en un teléfono

Está desplegado y **nadie lo ha visto en un dispositivo real todavía**. Es lo
más barato y lo más valioso que queda pendiente.

Abrir `https://juanjodior.github.io/true_app/` desde un móvil y mirar **las dos
pantallas**:

- **El formulario de alta.** Debe verse en una sola columna, con la lista de
  borradores y la previsualización detrás de sus botones, sin scroll horizontal.
- **La Sala de Situación.** Esta es la pública, y es la que cambió sin que
  nadie lo hubiera planeado. Debe salir `_MobileBody` (mapa a pantalla completa
  con la hoja del expediente), no el cuerpo de escritorio encogido.

Dos cosas concretas que hay que confirmar o descartar ahí:

- **Zoom al enfocar un campo.** Se omitieron `maximum-scale`/`user-scalable=no`
  a propósito (bloquear el pinch-zoom es una regresión WCAG 1.4.4). El coste
  aceptado es que iOS puede hacer zoom al enfocar un campo de texto. Si molesta,
  la salida NO es bloquear el zoom: es subir el `font-size` de los campos.
- **El desplegable de categoría y los chips de campo.** En las capturas del bug
  salían apelotonados. La hipótesis es que eran síntomas de la rama de
  escritorio activa en móvil y desaparecen solos. Es hipótesis hasta que se
  mire.

Si algo falla, la captura y el ancho reportado valen más que cualquier
descripción.

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
agujero en la pirámide de tests.**

Y no es la primera vez: `PROJECT_CONTEXT.md` ya registraba que el bug más caro
del proyecto pasó por delante de 45 tests en verde y apareció usando la app de
verdad en el navegador. Dos veces el mismo patrón.

Las cuatro verificaciones del ciclo encontraron el mismo tipo de defecto cuatro
veces: **una aserción que no podía fallar**. Está detallado en
`PROJECT_CONTEXT.md` → "Trampas conocidas".

---

## 3. Estado del ciclo SDD `intake-responsive`

**Abierto.** Fase 9 commiteada y sin re-verificar.

| Fase | Qué | Estado |
|------|-----|--------|
| 1–4 | Breakpoints compartidos, fallbacks de filas, rama estrecha, limpieza de viewport en tests | Verificadas |
| 5–6 | Cobertura de escritorio, ajuste fino, umbrales fijados por igualdad | Verificadas |
| 7 | `<meta name="viewport">` + guard `test/web_index_viewport_test.dart` | Verificada |
| 8 | Requisito "Host Document Viewport Precondition" + corrección del proposal | Verificada |
| 9 | Quitado el escenario infalsable + grafía `user-scalable=0` + aserciones separadas | **Sin verificar** |

Última verificación (`verify-report.md`): `verdict: fail`, `blockers: 1`. Ese
blocker es justo lo que cierra la fase 9, pero nadie lo ha comprobado todavía.

`flutter test` → 169 verdes. `flutter analyze` → limpio.

### Cómo desbloquearlo

El ledger de runtime está en generación 7 con el objetivo consumido. Un
objetivo nuevo exige **reset explícito de mantenedor** — no es automático por
diseño, y **no vale reusar la etiqueta de work-unit anterior para colarse**.

```bash
# 1. Sacar la revisión actual
gentle-ai sdd-attempt status --cwd <repo> --change intake-responsive

# 2. Resetear con esa revisión exacta
gentle-ai sdd-attempt reset --cwd <repo> --change intake-responsive \
  --expected-revision "sha256:<la-de-arriba>" \
  --request-id "reset-intake-responsive-gen8" \
  --reason "Phase 9 closed the unfalsifiable-scenario blocker; re-verify archive readiness" \
  --actor "drex"

# 3. Adquirir y lanzar sdd-verify con el token devuelto
gentle-ai sdd-attempt acquire --cwd <repo> --change intake-responsive \
  --request-id "acquire-reverify-gen8" \
  --work-unit "reverify-intake-responsive-after-phase-9" \
  --evidence-goal "Confirm the unfalsifiable scenario is closed and the zoom guard covers both spellings; report blocker count for archive readiness" \
  --max-attempts 2 --max-changed-lines 1000
```

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
| 1 | Sin comprobar en dispositivo real | — | Sección 1. Bloquea saber si lo demás es real |
| 2 | Ciclo SDD abierto | `openspec/changes/intake-responsive/` | Sección 3 |
| 3 | Banda 1024–1199px | `intake_workspace_screen.dart` | La columna del formulario es `ancho - 260 - 380 - 40`, así que sólo llega a `formRowStack` (520) a partir de 1200. En toda esa banda **todas** las filas se apilan en pantallas de escritorio. Anticipado en `design.md:9`, ausente del proposal, sin test: `intake_desktop_layout_test.dart` sólo monta a 1440 |
| 4 | `SituationTopBar` desborda | `situation_top_bar.dart` | Bandas medidas: 980 (21px) y 1030–1080 (59→9px). Preexistente, fijado como está en `situation_breakpoints_test.dart`. Candidato a change propio |
| 5 | No hay capa de navegador real | `test/` | El guard del viewport tapa el agujero concreto, no la familia. Un E2E mínimo (Playwright) sobre el build web cerraría la clase entera |
| 6 | 260 y 380 son literales mágicos | `intake_workspace_screen.dart:58,250` | Deberían ser tokens en `lib/core/layout/breakpoints.dart`. El test los redeclara, lo que hoy funciona como red pero duplica la verdad |
| 7 | "Las seis secciones alcanzables a 360px" | — | Sólo evidenciado estáticamente; ningún test lo afirma a nivel de workspace |
| 8 | `isExpanded: true` en desplegables | `basic_data_section.dart:46,84` | Cambio cosmético en escritorio, sin test. Conocido y aceptado |
| 9 | Error en consola al arrancar | `updates_ticker.dart:46` | Preexistente, sin efecto visible |

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
