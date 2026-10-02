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
- D5 Carpetas de plataforma: conservar `windows/`; ¿retirar `android/ ios/ macos/ linux/`? Bloquea F0b.

## Principios de código limpio (todas las tareas)
- Una responsabilidad por archivo y componente; widgets pequeños y con nombre que dice su intención; sin lógica de negocio en widgets (providers y funciones puras testeables).
- Scope Rule: lo que usa una sola feature vive en esa feature; solo lo compartido sube a `lib/core/design/`.
- Capa `Ds*` sin dependencias de features. Tokens, no valores sueltos (color, espaciado, radios, movimiento).
- Identificadores en inglés; comentarios y textos de interfaz en español neutro, solo comentarios que expliquen un porqué no obvio.
- Sin dependencias nuevas salvo decisión expresa; `AppColors` se conserva hasta migrar la última pantalla.
- TDD estricto: RED → GREEN → REFACTOR con `flutter test`; goldens en 1440 y 390 px donde el plan lo indica.
- Una unidad de trabajo por commit, con sus pruebas y documentación; objetivo ≈ 400 líneas autoradas por unidad. Conventional Commits en español, sin atribución de IA. Sin push, PR ni merge sin que el usuario lo pida.

## Plan y comprobaciones
Orden: D0 → F0 → F1 → F2 → F4 → F5 → F3 → F6 → F7 → F8 → F9 → F10 → F11. Las fases posteriores a F1 se detallan en tareas concretas al llegar a ellas.

- [ ] D0: Reconciliar `DESIGN.md` y `docs/design/` con los hallazgos 1–7 (acceso, catálogo, plataformas, teselas, datos). Solo documentación; sin TDD (pasivo).
- [ ] F0a: Retirar código muerto y textos obsoletos: `cupertino_icons`, `mapSectionGradientProvider`, `activeCategoryProvider`, mensaje obsoleto de `export_case_button.dart`, descripción/identificadores de plantilla. Tests existentes en verde.
- [ ] F0b: Carpetas de plataforma no usadas y restos en `web/` (requiere D5).
- [ ] F1-T1: Tokens en `lib/core/design/tokens/` (color, espaciado, radios, movimiento, sombras) según `DESIGN.md` §3.
- [ ] F1-T2: Tipografía y empaquetado de IBM Plex Mono 400/500 (OFL) en `assets/fonts/` + `pubspec.yaml`.
- [ ] F1-T3: `DsTheme` (inputs, botones, diálogos, snackbars) sin romper las pantallas actuales.
- [ ] F1-T4: Átomos `DsBadge`, `DsStatusLabel`, `DsMonoLabel`, `DsStatCell`.
- [ ] F1-T5: `DsButton`, `DsIconButton` (≥ 44 px), `DsFilterChip`, `DsSegmented`.
- [ ] F1-T6: `DsGlassPanel`, `DsFormField`, `DsDialog`, `DsToast`, estados vacío/error.
- [ ] F2: Motor del mapa plano (máscara de tierra, proyección, cámara, pintor de puntos, marcadores, arcos).
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
