# Rediseño cinematográfico (dirección D)

## Objetivo y alcance
Reconstruir **solo la capa de presentación** de true_app con la dirección D elegida (globo 3D en portada y explorar, mapa plano 2D en el expediente, estética cinematográfica). Fuente de verdad del diseño: `DESIGN.md` y `docs/design/` (prototipo HTML en `docs/design/prototype/`; el lienzo vivo es https://claude.ai/artifact/QuGGgx7c6VL9oX1ziC1fwi).

Fuera de alcance: dominio, datos y aplicación (Supabase, borradores, envío atómico, ~636 tests) **no se tocan** salvo el contrato de datos de «Novedades» si se aprueba (decisión D4). No se retoma `case-auto-publish` (pausado) ni se mezcla con CRP.

## Base y rama
- Rama: `feat/cinematic-design-system`, creada desde `case-review-publish` en `c7d870b` (árbol limpio tras commitear el trabajo de CRP-04b: `514b15e`, `c7d870b`).
- Verificado antes de ramificar: `flutter analyze` sin incidencias; 636 tests aprobados.
- Del otro PC solo se incorporan `DESIGN.md` y `docs/design/`. Se descartan: rama pr4, bundle, patch, memoria Engram del otro PC.

## Hallazgos que corrigen los documentos de diseño (explorador, 2026-10-02)
Los documentos se escribieron contra una versión anterior del código. Hay que reconciliarlos (tarea D0):
1. **No hay acceso con clave.** El formulario ya no está detrás de una puerta: los borradores son locales sin sesión; la cuenta de Supabase (email + contraseña) solo se pide al iniciar sesión desde el pie del formulario (`intake_sign_in_screen.dart`, diálogo a pantalla completa). La pantalla «Acceso con clave» del diseño pasa a ser el **diálogo de inicio de sesión**; «Volver a la sala» y la sacudida se adaptan a ese flujo.
2. **El catálogo viene de Supabase**, no de `assets/data/cases.json` (retirado). Los estados cargando / error con reintento / vacío ya existen en `situation_map_stage.dart` y son la base de la pantalla Estados.
3. **Plataformas:** además de web existe la **entrega Windows para Iván** (ver `ivan-usb-delivery.md`). La carpeta `windows/` **no se elimina**; «despliegue solo web» de `DESIGN.md` §10 es incorrecto. `BackdropFilter`, `file_picker` y el rendimiento del globo se prueban también en Windows.
4. **Teselas:** el mapa usa Esri (`World_Dark_Gray_Base`), no CARTO; atribución «Mapa © Esri · OpenStreetMap». `map_config_test` fija ese texto.
5. **Fotos:** `TrueCrimeCase` ya tiene `photos` (`CasePhoto`: `url`, `caption`); lo que falta son datos. `updatedAt`/`updateKind` **no existen** en el modelo.
6. **El envío a revisión no tiene interfaz** (el servicio está listo; ningún botón lo usa). El rediseño del formulario debe dejar el sitio para «Enviar a revisión» pero **no lo implementa** (pertenece a CRP).
7. Restos reales por limpiar: `cupertino_icons`, `mapSectionGradientProvider`, `activeCategoryProvider` (nadie lo escribe), ticker con 4 actualizaciones inventadas, círculos de densidad fijos, mensaje «JSON copiado. Pégalo en assets/data/cases.json» (obsoleto), `com.example.true_app`, descripción «Base project…».

## Decisiones abiertas (se preguntan una a una, antes de la tarea que las necesita)
- D1 (RESUELTA: `CustomPainter` propio, sin dependencias) Globo: `CustomPainter` propio (recomendado) / paquete / sin globo. Bloquea F3.
- D2 Selector de ubicación del formulario: mantener `flutter_map` solo ahí (recomendado) / mapa de puntos con zoom. Bloquea F8.
- D3 (RESUELTA: ruta propia `/mapa`) Ruta propia `/mapa` o modo explorar como estado de la portada. Bloquea F4/F5.
- D4 (RESUELTA: ocultar «Novedades» hasta tener datos; no se toca el contrato) `updatedAt`/`updateKind`: añadirlos al contrato (afecta al payload de Supabase, a `draftToCaseJson` y al catálogo) o ocultar «Novedades» hasta tener datos. Bloquea F4.
- D5 Carpetas de plataforma: **resuelta (2026-10-02)**: se conserva `windows/` y se retiran `android/ ios/ macos/ linux/`.

## Principios de código limpio (todas las tareas)
- Una responsabilidad por archivo y componente; widgets pequeños y con nombre que dice su intención; sin lógica de negocio en widgets (providers y funciones puras testeables).
- Scope Rule: lo que usa una sola feature vive en esa feature; solo lo compartido sube a `lib/core/design/`.
- Capa `Ds*` sin dependencias de features. Tokens, no valores sueltos (color, espaciado, radios, movimiento).
- Identificadores en inglés; comentarios y textos de interfaz en español neutro, solo comentarios que expliquen un porqué no obvio.
- Sin dependencias nuevas salvo decisión expresa; `AppColors` se conserva hasta migrar la última pantalla.
- TDD estricto: RED → GREEN → REFACTOR con `flutter test`; goldens en 1440 y 390 px donde el plan lo indica.
- Una unidad de trabajo por commit, con sus pruebas y documentación; objetivo ≈ 400 líneas autoradas por unidad. Conventional Commits en español, sin atribución de IA. Sin push, PR ni merge sin que el usuario lo pida.

## Skills de diseño instaladas (2026-10-02)
Instaladas en `~/.claude/skills` y `~/.agents/skills` (MIT, origen y commit en `SOURCE.txt` de cada una): `emil-design-eng` (emilkowalski/skills) y `ui-ux-pro-max` (nextlevelbuilder/ui-ux-pro-max-skill). Revisadas antes de instalar: sin red ni ejecución de comandos; solo `--persist` escribe archivos.

Cómo se usan en el ciclo (la dirección D ya está decidida: **no** se reabre el diseño):
- `emil-design-eng` — revisión de movimiento y pulido en F1-T1 (tokens de movimiento), F4, F5 y F6. Formato de revisión: tabla Antes / Después / Motivo. Reglas que sí trasladamos a Flutter: frecuencia antes de animar, `ease-out` en entradas, UI < 300 ms, nunca entrar desde `scale(0)`, retroalimentación al pulsar (`scale` 0,97), salida más rápida que entrada, escalonado de 30–80 ms, movimiento reducido. Los términos solo-CSS (`@starting-style`, `clip-path`, `transition: all`) se traducen a `AnimatedScale`, `ClipPath`, curvas `Cubic` y tweens.
- `ui-ux-pro-max` — consultas focales con `--stack flutter` y `--domain ux` (accesibilidad, objetivos táctiles, carrusel con pausa, contraste en oscuro, formularios); checklist previa a entrega en F11 (`references/pro-rules.md`). **Prohibido** `--design-system` y `--persist`: ya existe `DESIGN.md` y no se genera un sistema paralelo.
- No se usa `frontend-design` ni `web-design-guidelines` (genera HTML/React y empuja a rediseñar; Flutter web pinta en canvas y casi ninguna regla ARIA/DOM aplica).
- Cada skill aporta criterios, no certifica nada: la QA visual, el teclado y el foco se comprueban en la ventana real (web y Windows).

## Plan y comprobaciones
Orden: D0 → F0 → F1 → F2 → F4 → F5 → F3 → F6 → F7 → F8 → F9 → F10 → F11. Las fases posteriores a F1 se detallan en tareas concretas al llegar a ellas.

- [x] D0: Reconciliar `DESIGN.md` y `docs/design/` con los hallazgos 1–7 (acceso, catálogo, plataformas, teselas, datos). Solo documentación; sin TDD (pasivo). Worker editó `DESIGN.md`, `screens.md` y `flutter-implementation.md`; verificado por búsqueda que `MapConfig.attribution` y `shortLabel` no son restos y que `AppColors.surface/accentSoft`, `CaseCategoryPresentation.description` y `#0175C2` sí lo son (repuestos en `DESIGN.md` §10). Pendiente de revisar contra la pantalla real: cómo es el pie de cuenta del formulario y si el diálogo de sesión tiene candado/mapa de fondo.
- [x] F0a (a456cde; worker + gentle-ai-verify 7/7 PASS, analyze 0, 636 tests; RED observado en el texto del SnackBar, el resto son borrados sin referencias): Retirar código muerto y textos obsoletos: `cupertino_icons`, `mapSectionGradientProvider`, `activeCategoryProvider`, `AppColors.surface/accentSoft`, `CaseCategoryPresentation.description`, mensaje obsoleto de `export_case_button.dart` (y su test), color `#0175C2` del manifest, descripción/identificadores de plantilla. Tests existentes en verde.
- [x] F0b (verify: analyze 0, 636 tests, build web y Windows OK): Retirar `android/ ios/ macos/ linux/` y sus entradas en `.metadata` (D5 resuelta). Comprobar analyze, tests y build web/Windows.
- [x] F1-T1 (worker + verify PASS: analyze 0, 667 tests, valores cotejados con DESIGN.md §3; contrastes sobre bgBase 8–17,9:1; hover 250 ms por la regla de movimiento de emil-design-eng): Tokens en `lib/core/design/tokens/` (color, espaciado, radios, movimiento, sombras) según `DESIGN.md` §3.
- [x] F1-T2 (worker + verify 7/7: analyze 0, 679 tests, build web empaqueta las fuentes; bodyLead en 700 porque la serif solo se empaqueta en Bold): Tipografía y empaquetado de IBM Plex Mono 400/500 (OFL) en `assets/fonts/` + `pubspec.yaml`.
- [x] F1-T3 (worker + verify PASS: analyze 0, 705 tests, build web OK; AppTheme retirado. Pendiente en F4/F10: reconciliar DsBreakpoints.desktop=1200 con Breakpoints.sidePanel=880; ThemeData fija estilos de escritorio, los móviles salen de DsTextStylesResolver): `DsTheme` (inputs, botones, diálogos, snackbars) sin romper las pantallas actuales.
- [x] F1-T4 (worker + verify PASS: analyze 0, 736 tests, build web OK; literales 12/13/24 y espaciado mono 0,18 quedan locales, promover a tokens si se repiten): Átomos `DsBadge`, `DsStatusLabel`, `DsMonoLabel`, `DsStatCell`.
- [x] F1-T5 (worker + verify PASS: analyze 0, 799 tests, build web OK; DsSegmented subido a 44 px; pendiente menor: transparente repetido en 3 archivos y tamaños de icono como literales): `DsButton`, `DsIconButton` (≥ 44 px), `DsFilterChip`, `DsSegmented`.
- [x] F1-T6 (f0488cd, a8b30c2, ca720cf; worker + verify 9/9: analyze 0, 899 tests, build web OK. Pendiente: DsToast.show necesita inset para no tapar la barra inferior de 68 px ni la barra superior; DsStateMessage se centra solo en horizontal): `DsGlassPanel`, `DsFormField`, `DsDialog`, `DsToast`, estados vacío/error.
- [x] F2 (cfe3101, 81e8093, 9618aad, 5e84977, bbfd946; 1138 tests): Motor del mapa plano (`docs/design/map-and-globe.md` §1–2; capa `lib/core/design/map/`, sin importar `features`; recibe datos planos).
  - [x] F2-T1 (worker + verify PASS: analyze 0, 915 tests; la rejilla tiene 884 celdas únicas, no ~650, docs corregidos): `DsLandGrid` (máscara 72×27, centros de celda, opacidad por celda) y `DsMapProjection` (lon/lat ↔ escena 1440×540). Puro, con pruebas numéricas.
  - [x] F2-T2 (worker + verify PASS + corrección con destinos móviles del prototipo: analyze 0, 949 tests; el prototipo usa min de los dos ajustes, el tope superior no se alcanza): `DsMapCamera` (traslación + escala), objetivos Mundo/Caso/Conexiones/Explorar escritorio/Explorar móvil como funciones puras, interpolación con `ease.fly`.
  - [x] F2-T3 (worker + verify PASS: analyze 0, 987 tests; arco degenerado a==b no es de longitud cero, es finito): Geometría de arcos (control cuadrático, punto medio de la etiqueta) y estados de marcador (tamaños, opacidad por selección/filtro/año). Puro.
  - [x] F2-T4a (worker + verify PASS: analyze 0, 1054 tests, build web OK; glow alpha 0,5 y sigma = radio/2 pendientes de revisión visual): `DsMapScene` base: capa de tierra (un `CustomPainter`, 884 puntos en 6 cubos de opacidad), cámara animada que reanuda desde el valor actual, marcadores con tamaño fijo en pantalla, toque con zona de 44 px y semántica por marcador.
  - [x] F2-T4b (worker + verify PASS: analyze 0, 1138 tests, build web OK; un solo commit que excede ~400 líneas por ser una unidad indivisible; pruebas repartidas en 4 archivos + test_support; pendiente revisión visual de brillo, pulso y píldoras): `DsMapScene` efectos: arcos con trazo discontinuo animado y aparición a los 600 ms, etiquetas de relación y de casos relacionados, pulso con un solo ticker, movimiento reducido (sin pulsos, sin vuelo).
- [ ] F4: Portada (tras F3; D3 ruta `/mapa` apilada sobre la portada para que Atrás funcione; D4 «Novedades» oculta; la búsqueda de la barra abre `/mapa` con la consulta aplicada, el filtrado se resuelve en F5).
  - [x] F4-T1 (worker + verify PASS: analyze 0, 1477 tests, build web OK; estado único: openMap desde el detalle sustituye el detalle y Atrás desde el mapa va a la portada; página provisional para F5): Ruta `/mapa` (`MapPath`, parser, delegate, controlador, `AppNavigation.openMap`, página provisional para F5). Tests: parser, delegate, `_RecordingNavigation`, frontera de navegación.
  - [x] F4-T2 (worker + verify PASS: analyze 0, 1504 tests; «Sin resolver» = CaseStatus.open; rango nulo ordena al final; DsStatusColors.delivered sin equivalente en el dominio): Lógica de portada: `featuredCasesProvider` (top 5 por `featuredRank`), mapeadores enum de dominio → `DsCategoryColors`/`DsStatusColors`, adaptador de conexiones → `DsMapConnection`. Pruebas unitarias; fixtures con 5 destacados.
  - [x] F4-T3 (6de7a4e, 5ed9f52; worker retomado dos veces tras caída + verify PASS: analyze 0, 1597 tests; dos tests corregidos por el padre: el resumen mide 116 px por redondeo de línea (se comprueba < 5 líneas) y el título de cada slide tiene su Y por anclaje inferior (se comprueba que no hay desplazamiento tras el cambio); ~1240 líneas de producción en 8 archivos, por encima del objetivo de 400; pendiente revisión visual; revisión RDD aprobada (review-03e27c2d2ae759d3) con dos avisos para F11: el cambio de movimiento reducido en caliente no corta la transición en curso y la cámara no se reorienta si cambian las coordenadas del caso activo sin cambiar su id): Héroe: estado del carrusel (7 s, pestañas, pausa con interacción y movimiento reducido), contenido y `DsGlobeScene` en modo portada.
  - [x] F4-T4 (9b9ac9b; worker + verify PASS: analyze 0, 1627 tests; reutiliza unsolvedCasesProvider existente (abiertos, límite 12); ~650 líneas de producción en 5 archivos; títulos de sección con tokens 27/23 y 11 px en vez de 30/24 y 12 del prototipo; con foto se oculta el año fantasma; el póster elevado se superpone a la cabecera; pendiente revisión visual de degradado, resplandor y capa «más», y rueda horizontal sin probar; revisión RDD aprobada (review-98ca79984d7b1014) con un aviso para F11: si el caso con hover sale de la lista, `_hoveredId` queda colgado y atenúa el resto): Fila «Sin resolver» y póster (color de categoría como respaldo, `photos.first` si existe).
  - [ ] F4-T5: Invitación al mapa («EL MAPA», `DsMapScene`), pie, estados de carga/error/vacío con `DsStateMessage` (textos fijados).
  - [ ] F4-T6: Carcasa nueva de `home_page` (barra superior, barra inferior móvil, cambio a formulario intacto) y retirada del ticker, círculos de densidad y tests viejos de la Sala.
- [ ] F5: Explorar (filtros, línea de tiempo, ficha de cristal).
- [x] F3 (fdb7dca y siguiente; 1436 tests): Motor del globo (`docs/design/map-and-globe.md` §3–4; `lib/core/design/globe/`; D1 resuelta). Se hace ANTES de F4/F5 porque portada y explorar lo montan.
  - [x] F3-T1 (worker + verify PASS: analyze 0, 1181 tests; antípodas eligen un círculo máximo arbitrario pero determinista): `DsGlobeMath` puro: vector (lat,lon) → esfera (R 400, R+3 marcadores, R+4+sin(πt)·Ω·70 arcos), rotación rotX·rotY, proyección con perspectiva P=2200 y visibilidad z2>40, tamaño de punto, orientación al objetivo con desenrollado de gy, puntos del arco de círculo máximo.
  - [x] F3-T2 (worker + verify PASS: analyze 0, 1248 tests, build web OK; tokens globeFly 1900, globeDriftStep 70, globeDriftTransition 80): `DsGlobeCamera` (gx, gy, escala, centro) + objetivos Portada/Explorar + interpolación (camino corto) + `ease.globe` 1900 ms + deriva 0,22°/70 ms. Puro.
  - [x] F3-T3 (worker + verify PASS: analyze 0, 1358 tests, build web OK; tierra 73 llamadas en portada y 54 en explorar con cuantización de 0,5 px; pendiente revisión visual: foco 38/32, brillo 30/25, borde de limbo 60 %, sigma del resplandor 75): `DsGlobeScene` base: cuerpo de esfera y sombreado, puntos de tierra (un painter), halo de categoría, marcadores, etiquetas proyectadas, toque 44 px, semántica.
  - [x] F3-T4 (worker retomado tras caída + verify PASS: analyze 0, 1436 tests, build web OK; la deriva corre también sin marcadores; pruebas grandes (434/395/447/648 líneas) sin dividir; pendiente revisión visual de arcos y deriva): `DsGlobeScene` efectos: arcos de 27 puntos secuenciales (900 + k·35 ms), deriva, etiquetas diferidas (1700 ms), movimiento reducido.
- [ ] F6: Expediente.
- [ ] F7: El archivo (directorio).
- [ ] F8: Inicio de sesión + formulario — requiere D2.
- [ ] F9: Estados, errores y avisos.
- [ ] F10: Móvil.
- [ ] F11: Pulido, accesibilidad, retirada de `AppColors`.

## Progreso
2026-10-02: rama creada, documentos de diseño incorporados, plan escrito contra el código actual. Ninguna línea de Dart modificada todavía.

## Siguiente paso
Commit de documentos (`DESIGN.md`, `docs/design/`, este plan) y ejecución de D0.
