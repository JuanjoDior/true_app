# Plan de implementación en Flutter

Cómo llevar la dirección D ([`DESIGN.md`](../../DESIGN.md)) al código existente. No cambia la lógica de dominio, datos ni aplicación: **solo presentación**, más un pequeño aumento del contrato de datos.

Estado de partida (verificado en el repositorio): Flutter web (más la entrega de escritorio para Windows; `windows/` se conserva), catálogo y cuentas en Supabase, Riverpod 3, `flutter_map` 8, enrutado por hash con `Navigator 2.0` (`AppRouterDelegate`), tema oscuro en `lib/core/theme/app_theme.dart`, pantallas en `lib/features/{home,cases}/presentation/`.

---

## 1. Estructura propuesta

```
lib/core/design/
  tokens/        colors.dart · typography.dart · spacing.dart · radii.dart · motion.dart · shadows.dart
  theme/         ds_theme.dart                      (ThemeData de inputs, botones, diálogos, snackbars)
  components/    ds_badge.dart · ds_status_label.dart · ds_mono_label.dart · ds_stat_cell.dart
                 ds_button.dart · ds_icon_button.dart · ds_filter_chip.dart · ds_segmented.dart
                 ds_glass_panel.dart · ds_form_field.dart · ds_dialog.dart · ds_toast.dart
                 ds_empty_state.dart · ds_error_state.dart · ds_poster_card.dart · ds_source_card.dart
lib/features/atlas/                                (mapa plano + globo; lógica pura + pintores)
  domain/        land_mask.dart · geo_projection.dart · camera_target.dart
  presentation/  flat_map_scene.dart · globe_scene.dart · map_markers.dart · connection_arcs.dart · year_scrubber.dart
lib/features/home/presentation/                    (portada: carrusel + filas + invitación al mapa)
lib/features/cases/presentation/                   (expediente, directorio, inicio de sesión, formulario, estados)
```

- `AppColors` (actual) **se conserva** mientras queden pantallas sin migrar; cada slice nuevo usa los tokens `Ds*`. Al migrar la última pantalla se borra `AppColors` y el código muerto (`DESIGN.md` §10).
- Comentarios y documentación en español, como en el resto del repositorio; identificadores en inglés.

## 2. Tipografía y recursos

| Acción | Detalle |
| --- | --- |
| Empaquetar **IBM Plex Mono** 400 y 500 | Licencia OFL. Añadir a `assets/fonts/` y a `pubspec.yaml` (`family: IBMPlexMono`). Sustituye `kMonoFamily = 'monospace'` |
| Mantener Noto Sans 400/500/600 y Noto Serif Bold | Ya declaradas (`NotoSans`, `NotoSerifDisplay`) |
| Sin `google_fonts` | Evita peticiones en tiempo de ejecución y parpadeo de fuente |
| Iconos | `Icons.*` de Material (sin nuevas dependencias); mismos trazos finos que el prototipo |

## 3. El globo 3D — decisión pendiente

> Decisión **D1** (abierta; bloquea F3). Las decisiones abiertas D1–D5 y su estado se llevan en `odd/tasks/cinematic-design-system.md`. Las reglas de uso de las skills de diseño instaladas (`emil-design-eng`, `ui-ux-pro-max`) están en la sección «Skills de diseño instaladas» de ese mismo archivo; no se duplican aquí.

| Opción | Esfuerzo | Riesgo | Notas |
| --- | --- | --- | --- |
| **A. `CustomPainter` propio** (recomendada) | Medio | Bajo | Proyección ortográfica en Dart (fórmulas en `map-and-globe.md` §3). ~650 puntos por fotograma con `canvas.drawPoints`. Sin dependencias. Control total del vuelo y del acabado |
| B. Paquete de globo de pub.dev | Bajo | Medio-alto | No evaluados. Habría que verificar mantenimiento, soporte web y si permiten marcadores/arcos/cámara controlada |
| C. Sin globo: solo mapa plano | Bajo | Ninguno | Pierde el efecto de portada; el resto del diseño no cambia |

Recomendación: **A**. Si el rendimiento en web no llega a 60 fps en móviles modestos, degradar a C en móvil (ya es plano por diseño).

## 4. Mapa plano y `flutter_map`

El diseño dibuja la tierra con **puntos**, no con teselas. Consecuencias:

1. **Se elimina `flutter_map` del mapa principal y del expediente** → desaparecen las peticiones a las teselas (hoy Esri `World_Dark_Gray_Base`, no CARTO) y la atribución «Mapa © Esri · OpenStreetMap» de esas pantallas.
2. ⚠️ **Riesgo — selector de ubicación del formulario.** En el mapa de puntos, 1° ≈ 4 px a escala mundial: pulsar para fijar un punto **no da precisión de ciudad**. Opciones:
   - **(Recomendada)** Mantener `flutter_map` *solo* en el selector del formulario (tema oscuro, con zoom), y conservar su atribución. El resto de pantallas usan el mapa de puntos.
   - Dar zoom/desplazamiento al mapa de puntos del formulario + los campos de «Ajuste manual» (latitud/longitud).
3. `reverse_geocoder.dart` (peticiones HTTP) no cambia; si usa Nominatim, su atribución sigue siendo obligatoria en el formulario.

Por tanto `flutter_map` y `latlong2` **no se eliminan del `pubspec.yaml`** salvo que se elija la segunda opción.

## 5. Mapeo de efectos a Flutter

| Efecto del prototipo | Implementación |
| --- | --- |
| Crossfade de slides + zoom lento | `Stack` de slides con `AnimatedOpacity` + `TweenAnimationBuilder<double>` de escala 1,10→1,00 (8 s) |
| Contenido escalonado del héroe | `AnimatedSlide` + `AnimatedOpacity` con `Interval` de retraso |
| Progreso tipo historias | `AnimationController` único del carrusel (7 s) que alimenta `FractionallySizedBox` de la barra activa |
| Hover del póster | `MouseRegion` + `AnimatedScale` + `AnimatedSlide` (−12 px) + `AnimatedOpacity` para atenuar hermanos (estado en un `InheritedNotifier` de la fila) |
| Cristal | `ClipRRect` + `BackdropFilter(ImageFilter.blur)` + `DecoratedBox` (solo en paneles estáticos) |
| Vuelo de cámara | `AnimationController` + `Matrix4Tween` (o `TweenAnimationBuilder<Matrix4>`) con `Curves` personalizadas `ease.fly` |
| Contraescala de marcadores | En el `CustomPainter`: aplicar `1/k` al radio al dibujar, sin widgets por marcador |
| Pulso de marcadores | **Un solo** `AnimationController` global; cada marcador usa `(t + i·0,137) % 1` (no un controlador por marcador) |
| Arcos discontinuos animados | `Path` cuadrático + `PathMetric` con `dashOffset` animado por el mismo controlador |
| Radar giratorio | `SweepGradient` + `Transform.rotate` en `CustomPainter`, o `RotationTransition` |
| Sacudida del inicio de sesión | `TweenSequence` de desplazamiento X (±10/9/6/4 px, 420 ms) |
| Esqueleto con brillo | `ShaderMask` con `LinearGradient` desplazado por un controlador |
| Giro de pantalla de lista | `AnimatedSwitcher` y `SliverList` con `Interval` escalonado (40 ms/fila) |
| Autoavance con pausa | `Timer`/controlador que se reinicia en cada interacción y se detiene con `MediaQuery.disableAnimations` |

Sin dependencias nuevas (no hace falta `flutter_animate`).

## 6. Estado (Riverpod) y enrutado

- Nuevos providers (autodispose donde tenga sentido):
  - `heroSlideProvider` (índice + temporizador).
  - `atlasViewProvider` — modo (`portada | explorar`), caso seleccionado, filtro de estado, año.
  - `atlasCameraProvider` — objetivo de cámara derivado de la selección (puro, testeable).
  - `directoryQueryProvider` — texto del filtro del archivo.
- Reutilizar sin cambios: `cases_providers.dart`, `case_search_service.dart`, `case_draft_providers.dart`, `draft_validator.dart`, `case_exporter.dart`.
- **Rutas** (`AppRoutePath`): `SituationRoomPath` pasa a ser **Portada** (`/`). El modo *explorar* es estado de esa escena (o ruta `/mapa` si se quiere enlace directo). `CaseDetailPath` (`/casos/<slug>`) y `UnknownAppPath` se mantienen. El directorio sigue siendo una hoja modal.
- Ajustar `AppRouteInformationParser` y pruebas de navegación existentes en consecuencia.

## 7. Contrato de datos

Añadir a `TrueCrimeCase` (opcionales, retrocompatibles):

| Campo | Tipo | Uso |
| --- | --- | --- |
| `updatedAt` | `DateTime?` | Ordena la fila «Novedades» |
| `updateKind` | enum `new · reopened · identityConfirmed · sourceAdded · statusChanged`? | Texto de la insignia |

Estado real: `updatedAt` y `updateKind` **no existen** (decisión **D4**, abierta). `TrueCrimeCase` sí tiene ya `photos` (`CasePhoto`: `url`, `caption`); faltan datos, no modelo. El catálogo viene de Supabase (`assets/data/cases.json` se retiró).

Si se aprueba D4, actualizar el payload de Supabase, el exportador del formulario (`case_exporter.dart`, `draftToCaseJson`) y la fusión de catálogo (`mergeDraftsIntoCatalog`: `droppedKeys` ya avisa de claves que el borrador no puede expresar) para no perder estos campos al republicar.

## 8. Fases (unidades de trabajo)

Cada fase es una unidad de **commit(s) con pruebas y documentación**, revisable por separado (objetivo ≈ 400 líneas de cambio autorado por unidad; si una fase excede, dividirla).
TDD estricto: prueba que falla → implementación → refactor.

| # | Fase | Contenido | Criterio de aceptación |
| --- | --- | --- | --- |
| F0 | Limpieza de restos reales | `DESIGN.md` §10 (`windows/` se conserva; `android/ ios/ macos/ linux/` retiradas en F0b, decisión D5) | `flutter analyze` y `flutter test` en verde; build web OK |
| F1 | Sistema de diseño | tokens, tipografía + fuentes, `DsTheme`, átomos (`DsBadge`, `DsStatusLabel`, `DsMonoLabel`, `DsStatCell`, botones, chips, segmentado, panel de cristal, campo, diálogo, aviso, estados) | Pruebas de widget por componente; galería de componentes visible en una ruta de desarrollo |
| F2 | Motor del mapa plano | `land_mask`, proyección, cámara (objetivos Mundo/Caso/Conexiones), pintor de puntos, marcadores, arcos | Pruebas unitarias de proyección y cámara; golden del mapa en 1440 y 390 |
| F3 | Motor del globo | proyección ortográfica, orientación, pintor, deriva | Pruebas de las fórmulas (`map-and-globe.md` §3.2); prueba de rendimiento básica |
| F4 | Portada | navegación superior/inferior, carrusel, filas, pósters con hover, invitación al mapa | Coincide con `Globo.dc.html`/`Cine-Portada.dc.html`; autoavance y pausa testeados |
| F5 | Explorar | globo en modo explorar, filtros, línea de tiempo, ficha de cristal | Vuelo a caso, arcos y etiquetas; filtro y año reflejados |
| F6 | Expediente | cabecera, banda de mapa con vistas, cuerpo | Coincide con `Expediente-Cine.dc.html` y `Movil-Expediente.dc.html` |
| F7 | El archivo | hoja modal/inferior, filtro, filas | Orden por año desc., filtro sin tildes, estados vacío/error |
| F8 | Inicio de sesión + formulario | diálogo de inicio de sesión (email + contraseña), sitio reservado para «Enviar a revisión» (sin implementarlo), 3 paneles, vista previa en vivo, validación, selector de ubicación | Reglas de `draft_validator` intactas; copia de seguridad y exportación siguen funcionando |
| F9 | Estados | cargando, error, no existe, 404, vacíos, diálogos, avisos | Textos literales de `screens.md` §9 |
| F10 | Móvil | barra inferior, portada, mapa, expediente, formulario < 1200 px | Probado en 390 px; objetivos ≥ 44 px |
| F11 | Pulido | accesibilidad, movimiento reducido, rendimiento, limpieza de `AppColors` y código muerto | Lista de `DESIGN.md` §7 cumplida |

Orden recomendado: **F0 → F1 → F2 → F4 → F5 → F3 → F6 → F7 → F8 → F9 → F10 → F11** (el globo F3 puede retrasarse y entrar después de tener la portada con mapa plano).

## 9. Pruebas

- Hoy: 636 pruebas aprobadas (verificado el 2026-10-02) repartidas en `test/`. Las de **dominio, datos y aplicación no cambian**.
- Las de **presentación** (home, dossier, directorio, intake) se reescriben por fase, mantenido los textos literales como contrato.
- Nuevas: proyección/cámara (puras), generación de puntos de la máscara, orden y filtrado del directorio, validez del formulario, sacudida/estados del inicio de sesión, autoavance del carrusel (con `FakeAsync`).
- *Golden tests* para mapa, portada, expediente y estados en 1440 y 390 px.

## 10. Riesgos

| Riesgo | Mitigación |
| --- | --- |
| Rendimiento del globo y del desenfoque en web | `CustomPainter` único, cristal solo en paneles estáticos, degradar a plano en móvil |
| Precisión del selector de ubicación con mapa de puntos | Mantener `flutter_map` en el formulario (§4) |
| Reescribir muchas pruebas de presentación | Migrar por fases; conservar `AppColors` hasta el final |
| Falta de datos para Novedades y fotos | Contrato de datos (§7); mientras tanto ocultar la fila/sección si no hay datos |
| Resúmenes de ejemplo del prototipo no son reales | El diseño no fija textos de contenido; salen siempre del JSON |

## 11. Preguntas abiertas

> Corresponden a las decisiones D1–D5 de `odd/tasks/cinematic-design-system.md`, que es donde se registra su estado. D5 (carpetas de plataforma) quedó resuelta: se retiraron `android/ ios/ macos/ linux/` y se conserva `windows/`.

1. ¿Globo con `CustomPainter` propio (A), paquete (B) o sin globo (C)?
2. ¿Selector de ubicación con `flutter_map` (recomendado) o con mapa de puntos + zoom?
3. ¿Ruta propia `/mapa` o el modo explorar solo como estado de la portada?
4. ¿Se añaden `updatedAt` y `updateKind` al JSON ahora o se oculta «Novedades» hasta tener datos?
5. ¿Fotografías reales de los casos? (el modelo ya tiene `photos`; hoy no hay datos)
