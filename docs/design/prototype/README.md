# Prototipo — Dirección D

Código fuente (HTML + JS) de las pantallas del prototipo navegable.
Sirven de **referencia exacta de valores** (medidas, colores, curvas, tiempos, textos) al implementar en Flutter. **No forman parte de la app.**

Prototipo vivo: https://claude.ai/artifact/QuGGgx7c6VL9oX1ziC1fwi (filas «Dirección D»; pulsa *Play* en las pantallas interactivas).

> Los archivos `.dc.html` están escritos para el lienzo de Claude Design y necesitan su runtime (`support.js`) para abrirse. Léelos como especificación, no como página web independiente.

| Archivo | Pantalla | Interactiva |
| --- | --- | --- |
| `Globo.dc.html` | Portada + globo 3D + modo explorar | sí |
| `Cine-Portada.dc.html` | Filas «Novedades» y «Sin resolver», invitación al mapa, pie (el héroe plano de esta versión lo sustituye `Globo.dc.html`) | sí |
| `Expediente-Cine.dc.html` | Expediente con mapa 2D protagonista | sí |
| `Formulario-Cine.dc.html` | Formulario de casos (3 paneles) | sí |
| `Acceso.dc.html` · `Acceso-Movil.dc.html` | Acceso con clave (clave de prueba: `demo`) | sí |
| `Archivo.dc.html` · `Archivo-Movil.dc.html` | El archivo (directorio) | sí |
| `No-Encontrada.dc.html` | Dirección no encontrada | animada |
| `Estados.dc.html` | Estados, errores, diálogo y avisos | animada |
| `Movil-Portada.dc.html` · `Movil-Mapa.dc.html` · `Movil-Expediente.dc.html` | Móvil | sí |

## Dónde mirar cada cosa

- **Tokens de color/tipografía/espaciado:** `DESIGN.md` §3 (los valores salen de estos archivos).
- **Máscara de tierra, proyección, cámara:** bloque `renderVals()` de `Globo.dc.html` y `Expediente-Cine.dc.html`; resumido en `../map-and-globe.md`.
- **Tiempos y curvas de animación:** cadenas `transition`/`animation` dentro de cada `renderVals()`.
- **Textos literales:** marcado HTML de cada archivo; consolidados en `../screens.md`.

## Datos de ejemplo

Los resúmenes, estados y «Novedades» de los casos (salvo Zodiac y Black Dahlia, que coinciden con el JSON real) son **texto de ejemplo** escrito para el prototipo. Los cifras de la barra (p. ej. «8 sin resolver», «137 años») también son ilustrativas. La app debe leer siempre `assets/data/cases.json`.
