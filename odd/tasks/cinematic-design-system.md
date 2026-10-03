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
- D1 Globo: `CustomPainter` propio (recomendado) / paquete / sin globo. Bloquea F3.
- D2 Selector de ubicación del formulario: mantener `flutter_map` solo ahí (recomendado) / mapa de puntos con zoom. Bloquea F8.
- D3 Ruta propia `/mapa` o modo explorar como estado de la portada. Bloquea F4/F5.
- D4 `updatedAt`/`updateKind`: añadirlos al contrato (afecta al payload de Supabase, a `draftToCaseJson` y al catálogo) o ocultar «Novedades» hasta tener datos. Bloquea F4.
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
- [ ] F2: Motor del mapa plano (`docs/design/map-and-globe.md` §1–2; capa `lib/core/design/map/`, sin importar `features`; recibe datos planos).
  - [x] F2-T1 (worker + verify PASS: analyze 0, 915 tests; la rejilla tiene 884 celdas únicas, no ~650, docs corregidos): `DsLandGrid` (máscara 72×27, centros de celda, opacidad por celda) y `DsMapProjection` (lon/lat ↔ escena 1440×540). Puro, con pruebas numéricas.
  - [x] F2-T2 (worker + verify PASS + corrección con destinos móviles del prototipo: analyze 0, 949 tests; el prototipo usa min de los dos ajustes, el tope superior no se alcanza): `DsMapCamera` (traslación + escala), objetivos Mundo/Caso/Conexiones/Explorar escritorio/Explorar móvil como funciones puras, interpolación con `ease.fly`.
  - [x] F2-T3 (worker + verify PASS: analyze 0, 987 tests; arco degenerado a==b no es de longitud cero, es finito): Geometría de arcos (control cuadrático, punto medio de la etiqueta) y estados de marcador (tamaños, opacidad por selección/filtro/año). Puro.
  - [ ] F2-T4: `DsMapScene` (un `CustomPainter` de puntos, marcadores con contraescala `1/k`, pulso, arcos con trazo discontinuo animado, semántica 44×44, movimiento reducido).
- [ ] F4: Portada (carrusel, filas, pósters, invitación al mapa) — requiere D3, D4.
- [ ] F5: Explorar (filtros, línea de tiempo, ficha de cristal).
- [ ] F3: Motor del globo — requiere D1.
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
