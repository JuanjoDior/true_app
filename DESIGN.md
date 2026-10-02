# DESIGN.md — True · Archivo de casos

> Fuente de verdad del diseño. Dirección elegida: **D · Cinemática** (globo 3D + mapa plano 2D).
> Las direcciones A (nocturna), B (papel) y C (cine plano) se **descartaron**; no se implementan.
>
> Prototipo navegable: https://claude.ai/artifact/QuGGgx7c6VL9oX1ziC1fwi (filas "Dirección D").
> Código fuente de las pantallas del prototipo: [`docs/design/prototype/`](docs/design/prototype/).

## Índice de documentos

| Documento | Contenido |
| --- | --- |
| `DESIGN.md` (este) | Concepto, principios, tokens, tipografía, componentes, movimiento, accesibilidad, navegación y cambios funcionales |
| [`docs/design/screens.md`](docs/design/screens.md) | Especificación pantalla a pantalla (escritorio y móvil), textos literales e interacciones |
| [`docs/design/map-and-globe.md`](docs/design/map-and-globe.md) | Mapa plano 2D y globo 3D: proyección, cámara, marcadores, arcos, máscara de tierra |
| [`docs/design/flutter-implementation.md`](docs/design/flutter-implementation.md) | Cómo llevarlo a Flutter: estructura, fases, dependencias, contrato de datos, pruebas |

---

## 1. Concepto

Un archivo de crímenes reales presentado como **una sala de cine oscura**: contenido protagonista, cristal y luz sobre negro, movimiento que guía la atención.
Tres ideas lo sostienen:

1. **El mapa es el héroe.** La portada es un globo que gira hacia cada caso destacado; el expediente abre con un mapa plano a todo el ancho que vuela hasta el lugar.
2. **Catálogo como plataforma de streaming.** Carrusel de "En el foco", filas horizontales (Novedades, Sin resolver), pósters con hover que se elevan y oscurecen al resto.
3. **Respeto.** Es un archivo de víctimas reales. El tono visual es dramático pero contenido: sin gore, sin efectos de "susto", sin ornamento gratuito. El pie lo dice siempre: *«Crímenes reales · documentados con respeto. Las víctimas se nombran con respeto.»*

## 2. Principios

- **Una cosa que sorprende por pantalla**, el resto se calla (globo en portada, vuelo de cámara en mapa/expediente, radar en cabecera, sacudida en el inicio de sesión).
- **Todo efecto explica algo**: la cámara vuela para mostrar dónde ocurrió; los arcos dorados muestran relación entre casos; el pulso marca lo seleccionado.
- **Nada que parezca interactivo y no lo sea.** Se eliminaron los elementos inertes del diseño anterior (ver §10).
- **Contraste primero.** Texto ≥ 4,5:1 sobre su fondo; el color nunca es el único portador de significado (categoría y estado llevan texto).
- **Objetivos táctiles ≥ 44 px** en todas las plataformas.
- **Movimiento con `prefers-reduced-motion`/`MediaQuery.disableAnimations`**: se sustituye el vuelo de cámara por corte, y se detiene el autoavance del carrusel.

## 3. Tokens

### 3.1 Color

| Token | Valor | Uso |
| --- | --- | --- |
| `bg.base` | `#05070B` | Fondo de toda la app |
| `bg.glow` | `#0D1320` | Centro del degradado radial de fondo |
| `surface.chrome` | `rgba(10,13,19,0.88)` | Barra inferior móvil, cabeceras con desenfoque |
| `surface.glass` | `rgba(14,16,22,0.82)` (+ blur 18) | Fichas flotantes, hojas, diálogos |
| `surface.glassStrong` | `rgba(14,16,22,0.94)` | Hoja móvil del archivo |
| `surface.card` | `rgba(255,255,255,0.03–0.05)` | Tarjetas internas, secciones |
| `surface.input` | `#0D1118` | Campos de texto |
| `line.hairline` | `rgba(255,255,255,0.08–0.14)` | Bordes y divisores |
| `line.input` | `#2A303B` | Borde de campos |
| `text.strong` | `#FFFFFF` | Títulos sobre oscuro |
| `text.primary` | `#F4F1EB` | Texto principal |
| `text.body` | `#D8D3CA` | Párrafos |
| `text.muted` | `#B9B4AB` | Etiquetas, metadatos |
| `text.faint` | `#A7A29A` | Atribuciones, ayudas |
| `text.placeholder` | `#8B8880` | Placeholders |
| `accent.red` | `#E5484D` | Marca, CTA de formulario, barras de progreso |
| `accent.redText` | `#FF7A7F` | Errores y texto rojo pequeño (contraste ≥ 4,5) |
| `accent.gold` | `#F0C674` | Datos (año, coordenadas), arcos de conexión |
| `cta.bg` / `cta.fg` | `#F4F1EB` / `#0B0C10` | Botón primario |
| `cta.glass` | `rgba(255,255,255,0.14)` + borde `rgba(255,255,255,0.24)` | Botón secundario |

**Categorías** (punto, contorno de insignia y marcador del mapa):

| Categoría | Color | Base de póster |
| --- | --- | --- |
| Asesinos en serie (`serialKiller`) | `#E5484D` | `#2A0B10` |
| Asesinato aislado (`isolatedMurder`) | `#D9788A` | `#2A1219` |
| Secuestro (`kidnapping`) | `#E0A63A` | `#2B1E0A` |
| Caso sin resolver (`unsolved`) | `#5AA0D0` | `#0B1F2E` |

**Estados:** `open` `#6CB0E0` · `solved` `#8FCB8A` · `inProgress` `#F0B455` · (borrador entregado) `#B7A2F0`.
La etiqueta visible prefiere el `statusLabel` libre del JSON (p. ej. «Sin condena», «Resuelto (2005)»).

**Tierra del mapa:** puntos `#33405A` (plano) y `#5C7399` (globo), opacidad 0,45–0,95 según `((col*7 + fila*13) % 6)/10 + 0,45`.

### 3.2 Tipografía

| Rol | Familia | Peso | Notas |
| --- | --- | --- | --- |
| Display | Noto Serif (paquete `NotoSerifDisplay`) | 700 | Títulos, años grandes, nombres de caso |
| UI / cuerpo | Noto Sans | 400 · 500 · 600 | Texto corrido, botones, filas |
| Mono | **IBM Plex Mono** | 400 · 500 | Etiquetas en mayúsculas, coordenadas, fechas, URIs. **Hay que empaquetarla** (hoy el código usa `monospace` genérico) |

Escala (escritorio → móvil):

| Estilo | Escritorio | Móvil |
| --- | --- | --- |
| `display.hero` (título del foco / caso) | 88–120 / lh 0,94–0,96 / ls −0,01em | 50–64 |
| `display.page` (El archivo, Zodiac en ficha) | 40–44 | 32–34 |
| `display.card` (título en ficha flotante) | 34–36 | 30–32 |
| `display.section` | 24–30 | 22–24 |
| `display.poster` | 19–26 | 17–21 |
| `display.ghostYear` (año gigante decorativo) | 460–520, blanco 4,5–5 % | 250 |
| `body.lead` (resumen en expediente) | 30 serif / lh 1,4 | 23 |
| `body.large` | 18 / lh 1,6 | 15 |
| `body` | 14–16 / lh 1,55–1,7 | 14–16 |
| `ui.button` | 14–16 / 600 | 15 |
| `mono.label` | 11 / ls 0,12–0,24em / MAYÚSCULAS | 11 |
| `mono.data` | 12–16 / 400–500 | 12–15 |

Etiquetas mono: nunca por debajo de **11 px** (el diseño anterior usaba 8 px).

### 3.3 Espaciado y forma

- Base 4 px. Escala usada: 4 · 8 · 10 · 12 · 14 · 16 · 18 · 20 · 24 · 28 · 32 · 40 · 48 · 80.
- Margen lateral de página: **80 px** escritorio · **16 px** móvil.
- Radios: insignia 6 · botón/campo 10–14 · tarjeta 12–16 · ficha/hoja 18–26 · pastilla 999 · icono 60×60 = 18.
- Elevación (cristal): `0 30px 80px rgba(0,0,0,.6)`; hoja modal `0 50px 120px rgba(0,0,0,.7)`; póster en hover `0 34px 70px rgba(0,0,0,.65)`.
- Cristal = fondo translúcido + `BackdropFilter(blur 14–24)` + borde 1 px `line.hairline`.

### 3.4 Movimiento

| Token | Valor | Uso |
| --- | --- | --- |
| `ease.ui` | `cubic-bezier(.2,.8,.2,1)` | Hovers, apariciones, hojas, filas |
| `ease.fly` | `cubic-bezier(.22,.8,.2,1)` | Vuelo de cámara del mapa plano |
| `ease.globe` | `cubic-bezier(.45,.05,.2,1)` | Giro y cambio de escala del globo |
| `dur.hover` | 250–450 ms | Póster (elevar 12 px + escala 1,06), botones (escala 1,04), chips (desplazar 4 px) |
| `dur.crossfade` | 900 ms | Cambio de slide del héroe |
| `dur.kenBurns` | 7–8 s lineal | Zoom lento 1,10 → 1,00 del fondo activo |
| `dur.fly` | 1700–1900 ms | Vuelo de cámara / giro del globo |
| `dur.carousel` | 7 s escritorio · 6,5 s móvil | Autoavance del héroe |
| `dur.pulse` | 1,8 s (seleccionado) · 3 s (resto) | Anillo del marcador, escalonado `i*0,41 s` |
| `dur.dash` | 1,2 s lineal infinito | Arcos de conexión (desplazamiento del trazo) |
| `dur.stagger` | 40 ms/fila (máx. 10) | Listas |

Reglas de orquestación:
- Tras un vuelo, **la ficha aparece con retraso** (700–1500 ms) para no competir con el movimiento.
- Los arcos aparecen *después* de que la cámara llegue (600 ms de retraso); las etiquetas de relación, tras los arcos.
- Al cambiar de slide: el contenido saliente desaparece en 350 ms; el entrante entra en 900 ms con 350–450 ms de retraso.
- Las animaciones decorativas (radar, pulso, brillo) **no** bloquean la interacción.

## 4. Componentes

Cada componente lista su comportamiento. Nombres propuestos para Flutter (`Ds*`).

| Componente | Descripción | Estados |
| --- | --- | --- |
| `DsLogoMark` | Cuadrado rojo 36 (r10) con «T» serif blanca + «TRUE» serif 20 ls 0,1em | — |
| `DsTopNav` | Logo · enlaces (Inicio, Globo/Mapa, Archivo, Formulario) · búsqueda píldora 300 px | activo = blanco 600 + subrayado rojo 2 px |
| `DsBottomTabBar` (móvil) | 68 px, vidrio, 4 pestañas icono+etiqueta | activa = blanco 600 |
| `DsPrimaryButton` | Fondo `#F4F1EB`, texto `#0B0C10`, 52–56 alto, r12, icono flecha | hover escala 1,04 · deshabilitado |
| `DsGlassButton` | Translúcido + borde, mismo tamaño | hover escala 1,04 |
| `DsOutlineButton` | Transparente, borde `rgba(255,255,255,.22–.3)` | — |
| `DsIconButton` | 44×44 mín., r12 | hover fondo 10 % |
| `DsBadge` | Contorno 1 px + texto del color de categoría, 26–28 alto, r6, 12–13/600 | — |
| `DsStatusLabel` | Punto 8 + texto en color de estado | — |
| `DsMonoLabel` | Etiqueta de sección en mayúsculas 11 px ls 0,14–0,22em | — |
| `DsStatCell` | Etiqueta mono + valor (serif/mono dorado) | — |
| `DsFilterChip` | Píldora 40 alto; activo = `#F4F1EB`/texto oscuro 600; inactivo = cristal | activo · inactivo |
| `DsSegmented` | Contenedor r12–14 con opciones 36–44 alto | seleccionada = fondo claro |
| `DsGlassPanel` | Cristal (§3.3) | — |
| `DsPosterCard` | 236×350 (escritorio) · 156×232 (móvil) · 400×225 / 290×168 (apaisado). Degradado por categoría, año fantasma, insignia de novedad, título+lugar abajo | hover: eleva, dimma hermanos a 0,45, cambia a capa «más» con resumen |
| `DsHeroCarousel` | 5 slides crossfade + ken burns, año fantasma, contenido escalonado, barras de progreso clicables | pausa al interactuar (reinicia temporizador) |
| `DsTimeline` (datos) | Línea vertical degradada rojo→azul, fecha serif 22–26 coloreada, punto con halo | — |
| `DsMapScene` | Mapa plano de puntos con cámara, marcadores, arcos, etiquetas (ver `map-and-globe.md`) | mundo · caso · conexiones |
| `DsGlobeScene` | Globo 3D de puntos (ver `map-and-globe.md`) | portada · explorar |
| `DsYearScrubber` | Año grande + reproducir + deslizador + marcas por caso | reproduciendo |
| `DsSourceCard` | Título + host mono + icono flecha; hover eleva 5 px | — |
| `DsRelatedCard` | Póster apaisado 130 alto con año fantasma | hover eleva |
| `DsFormField` | Etiqueta 13/500 + campo 48 alto r12 `#0D1118`; foco: borde rojo + halo 3 px | foco · error · deshabilitado |
| `DsEmptyState` / `DsErrorState` | Icono 60 (r18) + título serif + texto + acción | ver `screens.md` §Estados |
| `DsToast` | Borde verde 50 %, icono check, desliza desde la derecha | 3 s |
| `DsDialog` | Cristal 20 radio, título serif 22, acciones a la derecha | — |

## 5. Mapa y globo (resumen)

- **Globo 3D** (portada y modo explorar): esfera de puntos R=400, perspectiva 2200. El carrusel del héroe dirige el giro; «Explorar el globo» lo desplaza y reduce, y aparecen filtros, línea de tiempo y ficha.
- **Mapa plano 2D** (expediente escritorio y todo el móvil): rejilla equirectangular de puntos de 5°, cámara que vuela entre **Caso / Conexiones / Mundo**.
- Marcadores con pulso, arcos dorados entre casos conectados, etiquetas con contraescala para mantener tamaño constante al hacer zoom.

Detalle completo, fórmulas y la máscara de tierra en [`docs/design/map-and-globe.md`](docs/design/map-and-globe.md).

## 6. Navegación

```
/                       Portada (globo + carrusel + filas)            [nuevo]
/mapa                   Globo en modo explorar (escritorio) / Mapa plano (móvil)
/casos/<slug>           Expediente (mapa 2D protagonista)
/archivo                El archivo (hoja modal escritorio · hoja inferior móvil)
/formulario             Formulario de casos (3 paneles / 1 panel); sin sesión los borradores son locales
cualquier otra          Dirección no encontrada
```

- Enrutado con hash (`/#/…`) como hoy. `SituationRoomPath` pasa a ser la **Portada**; el modo explorar/mapa es estado de esa misma escena.
- Escritorio: barra superior (Inicio · Globo · Archivo · Formulario). Móvil: barra inferior (Inicio · Mapa · Archivo · Formulario).
- «Archivo» abre la hoja modal sobre la escena atenuada (no es una ruta a pantalla completa).
- «Formulario» abre el formulario directamente: no hay puerta de acceso. El **diálogo de inicio de sesión** (email + contraseña, cuenta de Supabase) se abre desde el pie de cuenta del formulario; sin sesión los borradores funcionan en local.

## 7. Accesibilidad

- Contraste: texto pequeño sobre oscuro ≥ 4,5:1 (usar `accent.redText` y `text.muted`, nunca `accent.red` para texto de 12–14 px).
- Foco visible en todo control (borde rojo + halo 3 px).
- Semántica: marcadores del mapa = botones con `Semantics(label: nombre del caso)`; alertas de error con `liveRegion`; diálogo con rol de diálogo.
- El color de categoría/estado siempre acompañado de texto.
- Orden de tabulación = orden visual. Teclado: `Esc` cierra la hoja del archivo y la ficha del mapa; flechas izquierda/derecha cambian de slide del héroe.
- Movimiento reducido: sin autoavance, sin vuelo (corte directo), sin pulsos.

## 8. Contenido y tono

- Español de España, tuteo, frases cortas, sin exclamaciones.
- Nunca "morbo": títulos = nombre del caso; metadatos = lugar y año; víctimas "con respeto".
- Textos literales de cada pantalla en `docs/design/screens.md` (respetan los actuales de la app).

## 9. Cambios funcionales respecto a la app actual

**Se añade**
- **Portada** nueva: carrusel «En el foco» (basado en `featuredRank`), filas «Novedades» y «Sin resolver», invitación al mapa.
- **Globo 3D** y **mapa plano con cámara** (Caso / Conexiones / Mundo).
- Botón **«Abrir expediente»** en la ficha del caso seleccionado (antes solo desde el tooltip).
- **Filtro de texto** dentro de «El archivo».
- **Vista previa en vivo**, **lista de campos obligatorios** y **pestañas de sección** en el formulario; el mapa del formulario se puede pulsar para fijar el punto.
- Botón **«Reintentar»** en estados de error de lectura.
- Enlace **«Volver a la sala»** en el diálogo de inicio de sesión (sustituye al antiguo acceso con clave; ya no existe el estado «Acceso concedido»).
- Solo se **reserva sitio** en el formulario para «Enviar a revisión» (hoy sin interfaz: el servicio está listo, pero el botón pertenece al cambio CRP); el rediseño no lo implementa.

**Se elimina (no hacía nada)**
- Píldora «Global ▾», insignia «⌘K», iconos *hub* y marcador del raíl, avatar del raíl, estrella y compartir del expediente, «Seguir el caso».
- Círculos de densidad falsos del mapa y la leyenda «El halo indica densidad…».
- Píldora «Crímenes reales…» sobre el mapa (el lema pasa al pie).
- **Ticker** de actualizaciones (4 actualizaciones inventadas en código); lo sustituye la fila **Novedades** (requiere datos reales, §11).
- Botones de archivo/formulario duplicados en la barra (la navegación ya los contiene).

**Se mantiene** (con rediseño visual)
- Búsqueda global, filtro por estado, línea de tiempo con reproducción, vista Mundo/Detalle, expediente (cronología, fuentes, relacionados, fotos, capítulos), directorio, formulario completo, copia de seguridad, exportación JSON, inicio de sesión (diálogo) desde el pie de cuenta.

## 10. Restos reales a limpiar (independiente del rediseño)

`cupertino_icons` sin uso · `mapSectionGradientProvider` · `activeCategoryProvider` (nadie lo escribe) · ticker con 4 actualizaciones inventadas · círculos de densidad fijos en el mapa · mensaje «JSON copiado. Pégalo en assets/data/cases.json» (obsoleto: el catálogo viene de Supabase) · identificador `com.example.true_app` · descripción «Base project…» · `AppColors.surface` y `AppColors.accentSoft` (sin lectores) · campo `CaseCategoryPresentation.description` (sin lectores) · color `#0175C2` en `web/manifest.json` e iconos por defecto de `web/icons/` (por confirmar). Comprobado que **no** son restos: `MapConfig.attribution` (se pinta en la leyenda del mapa) y `shortLabel` (lo usa el buscador).

**Plataformas.** Además de web existe la entrega de escritorio para Windows (`odd/tasks/ivan-usb-delivery.md`): la carpeta `windows/` **se conserva**. `android/ ios/ macos/ linux/`: decisión pendiente D5 (ver `odd/tasks/cinematic-design-system.md`). `BackdropFilter`, `file_picker` y el rendimiento del globo se prueban también en Windows.

## 11. Datos necesarios

El diseño muestra **Novedades** con etiqueta de tipo («Caso reabierto», «Identidad confirmada», «Nueva fuente», «Estado actualizado», «Nuevo expediente»). `updatedAt` y `updateKind` **no existen** en `TrueCrimeCase`; añadirlos al contrato (decisión D4, abierta) afecta al payload de Supabase, a `draftToCaseJson` y al catálogo. El catálogo viene de Supabase (`assets/data/cases.json` se retiró). Propuesta mínima por caso:

```json
{ "updatedAt": "2026-09-12", "updateKind": "reopened" }
```

`updateKind`: `new | reopened | identityConfirmed | sourceAdded | statusChanged`. La fila Novedades ordena por `updatedAt` descendente y muestra los N primeros.
El carrusel «En el foco» usa `featuredRank` (ya existente) ascendente.

## 12. Decisiones cerradas y pendientes

**Cerradas:** dirección D · globo en portada/explorar + mapa plano en expediente y móvil · botón «Abrir expediente» en la ficha · sin selector Globo/Plano en el expediente · A, B y C descartadas.

**Pendientes:**
1. Cómo renderizar el globo en Flutter (ver `docs/design/flutter-implementation.md` §3).
2. Fuente de datos para Novedades (§11).
3. Fotografías reales de los casos: `TrueCrimeCase` ya tiene `photos` (`CasePhoto`: `url`, `caption`), pero no hay datos; el diseño usa marcadores de posición.
4. Fuente de los resúmenes de los 12 casos que el prototipo rellenó como ejemplo (solo Zodiac y Black Dahlia salen del catálogo real).

Las decisiones abiertas vigentes del rediseño (D1–D5) se llevan en `odd/tasks/cinematic-design-system.md`.
