# Pantallas — Dirección D

Referencias de tokens y componentes: [`DESIGN.md`](../../DESIGN.md).
Prototipo: https://claude.ai/artifact/QuGGgx7c6VL9oX1ziC1fwi · fuentes en [`prototype/`](prototype/).
Medidas de escritorio sobre un lienzo de 1440 px; móvil sobre 390 px.

Los textos entre comillas son **literales** y deben respetarse.

---

## 1. Portada + Globo (`Globo.dc.html`)

Una sola escena con **dos modos**: *portada* y *explorar*.

### 1.1 Modo portada
- **Fondo:** degradado radial `#0B1220 → #05070B`, 70 estrellas parpadeantes (1–2 px), halo de color del caso activo detrás del globo.
- **Globo:** centro (1010, 520), escala 1,0 (radio 400 → parcialmente recortado abajo/derecha). Gira hasta la ubicación del slide activo (1900 ms `ease.globe`).
- **Velo de texto:** degradado lateral izquierdo 980 px (`rgba(5,7,11,.95) → 0`).
- **Carrusel «En el foco»** — 5 casos por `featuredRank` (ejemplo: Zodiac, La mujer de Isdal, El hombre de Somerton, Madeleine McCann, Paso Diátlov). Autoavance 7 s.
  - Kicker: «EN EL FOCO» (mono, color de categoría) · línea 32 px · «n / 5».
  - Título serif 88, lh 0,96.
  - Insignia de categoría (contorno) · «Lugar · año» · estado con punto.
  - Resumen 18/1,6, máx. 540 px.
  - Botones: **«Abrir expediente»** (primario, → `/casos/<slug>`) y **«Explorar el globo»** (cristal, pasa a modo explorar con ese caso seleccionado).
  - Año fantasma 460 px a la izquierda; coordenadas mono abajo a la derecha (80 px).
  - Pestañas inferiores (80 px izq., ancho 680): nombre del caso 13/600 + barra de 3 px que se rellena en 7 s; clicables.
- **Transiciones entre slides:** contenido saliente 350 ms; entrante 900 ms con 450 ms de retraso; año fantasma entra desde −60 px.

### 1.2 Modo explorar
- **Globo:** centro (640, 455), escala 0,78. Sin caso: deriva lenta (0,22° cada 70 ms). Con caso: gira hasta dejarlo de frente.
- **Arriba izquierda:** «GLOBO DE CASOS» (mono rojo) + «El archivo» (serif 44) + chips de estado: «Todos», «Sin resolver», «Resuelto», «En investigación».
- **Ficha de cristal** (derecha, 400 px, top 112): aparece 1500 ms después de iniciar el vuelo.
  - Cabecera 130 px con degradado de categoría, año fantasma, insignia de categoría y botón cerrar (44).
  - Título serif 36 · «Lugar · año» · estado · resumen 14/1,6.
  - Tres celdas: «AÑO» · «CONEXIONES» · «COORDS».
  - Casos conectados como botones (vuelan al otro caso).
  - **«Abrir expediente»** primario.
- **Arcos:** círculo máximo elevado (26 puntos dorados, brillo) entre el caso y sus conectados; se dibujan secuencialmente (35 ms/punto, 900 ms de retraso).
- **Etiquetas** proyectadas (caso y conectados) a 18 px del marcador; visibles 1700 ms después de iniciar el vuelo.
- **Leyenda** (abajo izq.): Serie · Aislado · Secuestro · Sin resolver.
- **Pista** (sin selección): «Selecciona un punto para volar hasta el caso».
- **Línea de tiempo** (barra de cristal inferior, 96 px): «HASTA» + año serif 52 · botón reproducir 52 (círculo claro) · marcas por caso coloreadas sobre el deslizador 1888–2025 · segmentado «Mundo | Detalle».
  - Reproducir: +2 años cada 70 ms; los casos aparecen según su año.
  - «Mundo»: quita la selección y vuelve a derivar. «Detalle»: selecciona el último caso visto.
- **Filtro de estado:** los que no coinciden bajan a opacidad 0,12; si hay selección, los no relacionados bajan a 0,35–0,40.

### 1.3 Navegación
Logo · Inicio · Globo · Archivo · Formulario · búsqueda «Buscar por nombre, lugar o año…».

---

## 2. Portada — filas (`Cine-Portada.dc.html`, secciones inferiores)

Debajo del héroe (mismo lenguaje que C, reutilizado en D):

- **Novedades** — «ÚLTIMAS ACTUALIZACIONES DEL ARCHIVO». Pósters 236×350, gap 16, recortados en el borde derecho con flecha circular de 52.
  - Insignia de novedad arriba izq. («Caso reabierto», «Identidad confirmada», «Nueva fuente», «Estado actualizado», «Nuevo expediente»).
  - Hover: sube 12 px, escala 1,06, el resto de la fila baja a opacidad 0,45; la capa base se desvanece y entra la capa «más» (título, estado, resumen, «Abrir expediente»).
- **Sin resolver** — «CASOS ABIERTOS QUE SIGUEN ESPERANDO RESPUESTA». Tarjetas 400×225.
- **Invitación al mapa** (540 alto): mapa de puntos con pulsos, «EL MAPA», «El archivo, punto por punto», texto «Cada caso tiene su lugar. Acércate, sigue las conexiones entre casos y recorre décadas con la línea de tiempo.», botón «Abrir el mapa».
- **Pie:** «TRUE» · «Crímenes reales · documentados con respeto. Las víctimas se nombran con respeto.»

---

## 3. Expediente (`Expediente-Cine.dc.html`)

### 3.1 Estructura (escritorio, 1440 de ancho)
1. **Cabecera 500 px:** degradado rojo de categoría, año fantasma 520 px, velo izquierdo. Abajo izq. (80 px): «← VOLVER AL GLOBO», insignia + estado + «· LUGAR · PAÍS · AÑO», **título serif 120**.
2. **Mapa 2D 620 px a todo el ancho** (ver `map-and-globe.md`):
   - Al cargar: vista Mundo → tras 1100 ms la cámara vuela a **Caso**.
   - **Ficha de ubicación** (izq., 360 px): «UBICACIÓN», nombre, «Lugar · año», «LATITUD» / «LONGITUD» mono dorado, «CASOS CONECTADOS» (botones que vuelan al otro caso). Si el caso enfocado no es el del expediente: botón **«Abrir expediente»**.
   - **Leyenda** (der., arriba) y **vistas de cámara** (der., abajo): «Caso · Conexiones · Mundo».
   - Atribución: «Mapa © Esri · OpenStreetMap» (teselas Esri `World_Dark_Gray_Base`, no CARTO; el texto lo fija `map_config_test`).
3. **Cuerpo:** dos columnas (1fr + 380 px, gap 72).
   - Principal: resumen en serif 30 · caja «VÍCTIMA(S)» · «LOS HECHOS» (capítulos) · «FOTOGRAFÍAS» (240×170, hover escala 1,05) · «CRONOLOGÍA VERIFICADA» (fecha serif 26 a la izquierda, línea degradada, punto con halo).
   - Lateral: celdas «AÑO» y «CONEXIONES» · «FUENTES CITADAS» (tarjetas con hover) · «CASOS RELACIONADOS» (póster apaisado 130 con año fantasma y relación).

Capítulos posibles: «Antecedentes», «Los hechos», «La investigación», «Estado actual». Solo se muestran los que tengan texto. Fotografías: solo si existen.

### 3.2 Móvil (`Movil-Expediente.dc.html`, 390 × contenido)
Cabecera 360 (título serif 64) → **mapa 440** con ficha compacta (230 px) arriba izq., chips de conectados y segmentado «Caso · Conexiones · Mundo» (44 alto) → cuerpo a una columna: resumen serif 23, celdas, víctimas, hechos, fotos en scroll horizontal, cronología (fecha sobre título), fuentes, relacionados, pie.

### 3.3 Interacciones
- Pulsar un marcador del mapa: vuela a ese caso y actualiza la ficha.
- «Abrir expediente» (solo caso distinto): navega a `/casos/<slug>`.

---

## 4. Móvil — Portada (`Movil-Portada.dc.html`)
- Héroe 640: barras de progreso tipo «historias» (16 px de margen, 6 de gap) bajo la cabecera; contenido inferior (título 50, insignia, lugar·año, estado, resumen, **«Abrir expediente»** + icono mapa 52×52).
- Filas con scroll horizontal: «Novedades» (pósters 156×232) y «Sin resolver» (290×168).
- Tarjeta «EL MAPA» (250 alto) con recorte del mapa de puntos → «Abrir el mapa».
- Barra inferior: Inicio · Mapa · Archivo · Formulario.

## 5. Móvil — Mapa (`Movil-Mapa.dc.html`)
- Mapa plano a pantalla completa (cámara general: escala 0,62 centrada en Atlántico).
- Chips de estado en scroll horizontal bajo la cabecera.
- **Hoja de cristal** al seleccionar (12 px de margen, radio 22): insignia, título 32, estado, resumen, chips de conectados (44 alto), **«Abrir expediente»** + «Mundo». Aparece 800 ms después del vuelo.
- Sin selección: pista «Toca un punto para volar hasta el caso».
- Mini línea de tiempo fija sobre la barra de pestañas: reproducir 44, marcas y deslizador, año serif 22.

---

## 6. El archivo — directorio (`Archivo.dc.html`, `Archivo-Movil.dc.html`)

- **Escritorio:** hoja modal 780 px (48 px de margen vertical, radio 26) sobre la escena desenfocada y atenuada. **Móvil:** hoja inferior a 56 px del borde superior, radio 26 arriba, asa de 40 px.
- Cabecera: «N EXPEDIENTES» (mono rojo; «k DE N EXPEDIENTES» si hay filtro) · **«El archivo»** serif 40 (34 móvil) · cerrar (48/44).
- **Filtro** (nuevo): «Filtrar por nombre, lugar o año…». Ignora tildes y mayúsculas; busca en título, lugar y año.
- **Filas** (76 px escritorio · 64 móvil), **orden por año descendente** (empate por título):
  año mono dorado · punto de categoría con brillo · título serif 19 + «Lugar · País» mono · estado con punto (solo escritorio) · chevron.
  Hover: fondo 7 %, desplaza 4 px, chevron 5 px. Entrada escalonada 40 ms.
- Sin resultados de filtro: «Ningún expediente coincide» / «Prueba con otro nombre, lugar o año.»
- Vacío y error: ver §9.

---

## 7. Inicio de sesión (`Acceso.dc.html`, `Acceso-Movil.dc.html`)

Sustituye a la antigua pantalla «Acceso con clave». **No hay puerta de acceso con clave compartida**: el formulario es accesible y los borradores se guardan en local sin sesión. El diálogo a pantalla completa (`intake_sign_in_screen.dart`) se abre desde el **pie de cuenta** del formulario y pide la cuenta de Supabase (email + contraseña). No hay registro ni recuperación de contraseña.

- Fondo: mapa de puntos apagado (55 %) con pulsos tenues + velo oscuro.
- Cabecera: logo · «VOLVER A LA SALA» (móvil: X); cierra el diálogo y vuelve al formulario sin sesión.
- **Tarjeta de cristal** 440 px (móvil: ancho completo − 32, abajo, 32 px del borde):
  - Icono candado 60×60 con halo rojo pulsante.
  - Kicker «ZONA RESERVADA».
  - **«Acceso al formulario de casos»** (serif 34 / 30).
  - «Entra con tu email y tu contraseña.»
  - Campos **«Email»** y **«Contraseña»** (esta oculta), 56 alto.
  - Error (rojo `#FF7A7F`, icono, `role=alert`) + sacudida horizontal de la tarjeta (420 ms) + borde rojo del campo. Textos reales: «Escribe tu email y tu contraseña.» (campos vacíos) · «El email o la contraseña no son correctos.» · «No se pudo conectar. Revisa la conexión y vuelve a probar.»
  - Botón **«Entrar»** (primario, 56 alto); mientras espera: **«Entrando…»** (deshabilitado).
  - Ayuda: «¿Sin cuenta o sin contraseña? Pídesela a quien revisa los casos.»
  - Éxito: no hay tarjeta de confirmación ni estado «Acceso concedido»; al entrar, el formulario sustituye al diálogo.
- Lógica: la sesión es la de Supabase (`intake_auth.dart`), no una constante compartida; la clave de prueba `demo` del prototipo **no existe** en la app.
- Pie: «Crímenes reales · documentados con respeto».

---

## 8. Formulario de casos (`Formulario-Cine.dc.html`)

### 8.1 Escritorio (≥ 1200 px): tres paneles
- **Barra superior (68):** volver · logo · «Formulario de casos» · **«Copia de seguridad ▾»** · **«Copiar JSON»** · **«Nuevo borrador»**.
  - Menú de copia de seguridad (280 px, cristal): «Guardar mi trabajo en un fichero» · «Cargar trabajo desde un fichero» · — · «Copiar como texto» · «Pegar un texto copiado».
  - «Copiar JSON»: deshabilitado (gris, `cursor: not-allowed`, con tooltip «Completa los campos obligatorios para poder exportar») hasta que todo sea válido; activo = rojo. Al pulsar: aviso de confirmación. El texto actual «JSON copiado. Pégalo en assets/data/cases.json» está **obsoleto** (el catálogo viene de Supabase y `cases.json` se retiró): el texto nuevo se decide en F8.
- **Borradores (280 px):** «BORRADORES · N». Tarjeta por borrador: título serif 17 (o «Sin título») + subtítulo con punto de color:
  «Incompleto» (ámbar) · «Listo · sin publicar» (azul) · «Entregado el DD/MM · pendiente de publicar» (violeta) · «Publicado» (verde). Icono papelera 36. Activo: fondo rojo 12 %, borde rojo, barra interior izquierda.
- **Formulario (centro, scroll):** pestañas fijas arriba (píldoras con número): «01 Datos básicos · 02 Ubicación · 03 Resumen · 04 Cronología · 05 Enlaces · 06 Fotografías · 07 Capítulos». Secciones en tarjetas de 24 px de padding:
  1. **Datos básicos:** «Título» · «Categoría» (Asesinos en serie / Asesinatos aislados / Secuestros / Casos sin resolver) · «Año» · «Estado» (Sin resolver / Resuelto / En investigación).
  2. **Ubicación:** mapa de puntos 280 alto, cursor cruz, **pulsar fija el punto** (marcador animado); chip «Toca el mapa para situar el caso»; línea «37.77° N · 122.42° O» o «Sin punto marcado» (durante la búsqueda: «Buscando el lugar…»); «País» · «Región o ciudad»; desplegable **«Ajuste manual»**: «Código ISO» (hint `ES`) · «Latitud» · «Longitud».
  3. **Resumen y ficha:** «Resumen del caso» · «Víctimas» (hint «Al menos 5 víctimas confirmadas»; ayuda «Descríbelas con respeto, como en el resto del archivo») · «Tags» (hint «1960s, ee. uu., cifrado»; ayuda «Separados por comas») · «Rango destacado» (hint «1 = destacado esta semana») · «Rango de relevancia».
  4. **Cronología:** filas «Fecha» (120) · «Qué ocurrió» · «Tipo» (Hecho inicial / Investigación / Sigue abierto / Resolución) · quitar; «Añadir hito».
  5. **Enlaces:** «Título del enlace» · «URL» · «Tipo» (Podcast / Vídeo / Documento / Publicación / Otro) · quitar; «Añadir enlace».
  6. **Fotografías:** «URL de la imagen» · «Pie de foto (opcional)» · quitar; «Añadir fotografía».
  7. **Capítulos:** «Antecedentes», «Los hechos», «La investigación», «Estado actual» (multilínea).
  - Bajo 520 px de ancho útil, las filas se apilan.
- **Previsualización (400 px):** ficha del caso en vivo (cabecera con degradado de categoría, título, lugar, estado, resumen, víctimas, año, coords) + panel **«CAMPOS OBLIGATORIOS»** con ✓ para: «Título», «Año (3 o 4 cifras)», «Punto en el mapa», «Resumen del caso».
- **Pie de cuenta** del formulario: estado de la sesión y acceso al diálogo de inicio de sesión (§7).
- **Sitio reservado para «Enviar a revisión»** (barra superior o pie de la previsualización). Hoy no tiene interfaz: el servicio está listo, pero el botón pertenece al cambio CRP; el rediseño deja el hueco y **no lo implementa**.
- Validez: título + año (3–4 dígitos) + punto + resumen no vacíos (las reglas reales siguen en `draft_validator.dart`).

### 8.2 < 1200 px
Un panel: barra con iconos (Borradores, Previsualización, copia de seguridad, copiar, nuevo). Borradores = hoja centrada con velo; previsualización = hoja inferior del 50 %. (Diseño móvil específico del formulario pendiente de maquetar con los mismos componentes.)

---

## 9. Estados, errores y avisos (`Estados.dc.html`, `No-Encontrada.dc.html`)

| Estado | Título | Texto | Acción |
| --- | --- | --- | --- |
| Expediente · cargando | — (radar giratorio + esqueleto con brillo) | — | — |
| Expediente · error de lectura | «No se pudo leer el archivo» | «El expediente puede seguir ahí. Vuelve a intentarlo en un momento.» | **Reintentar** (nuevo) |
| Expediente · no existe | «Ese expediente no existe» | «La dirección no corresponde a ningún caso publicado.» | «Volver al archivo» |
| El archivo · vacío | «Todavía no hay expedientes publicados.» | — | — |
| El archivo · error | — | «No se pudo leer el archivo. Inténtalo en un momento.» | **Reintentar** (nuevo) |
| Sala · sin destacado | «El archivo aún no tiene un caso destacado.» | «En cuanto se publiquen expedientes, aquí rotará un caso abierto cada semana.» | — |
| Formulario · sin borrador (edición) | — | «Crea o selecciona un borrador para editarlo.» | — |
| Formulario · sin borrador (vista previa) | — | «Crea o selecciona un borrador para previsualizarlo.» | — |
| Sala · catálogo cargando | — | «Cargando el archivo…» | — |
| Sala · catálogo con error | — | «No se pudieron cargar los casos.» | **Reintentar** (ya existe; «Reintentando…» mientras carga) |
| Diálogo «Restaurar borradores» | «Restaurar borradores» | campo con hint `{"schemaVersion": 1, "drafts": [...]}` | «Cancelar» · «Restaurar» |
| Avisos | — | «Trabajo guardado. Ya puedes enviar ese fichero.» · «JSON copiado. Pégalo en assets/data/cases.json» (obsoleto, ver §8.1) · «Cargados N casos. Los que ya tenías siguen aquí.» | — |

### 9.1 Dirección no encontrada (pantalla completa)
Mapa de puntos con una **estela dorada** desde un caso que se desvanece hacia un punto perdido en mitad del océano (anillos rojos expandiéndose, barrido de radar, «?» parpadeante).
Texto: kicker «SEÑAL PERDIDA» · **«Esta dirección no lleva a ningún sitio»** (serif 68) · URI en píldora mono · botón **«Volver al archivo»**.

Semántica de iconos de estado: ámbar = error de lectura · azul = no encontrado · rojo = acción del formulario · verde = éxito · gris = vacío.
