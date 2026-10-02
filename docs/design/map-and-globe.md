# Mapa plano y globo 3D

Especificación técnica de las dos representaciones del mapa. Valores tomados del prototipo (`prototype/Globo.dc.html`, `Expediente-Cine.dc.html`, `Movil-Mapa.dc.html`).

## 1. Rejilla de tierra (compartida)

El mundo se dibuja como **puntos**, no como polígonos. Una celda = **5° de longitud × 5° de latitud**.

- 72 columnas (lon −180…180) × 27 filas (lat 80…−55).
- Celda `(col, fila)` → longitud central `−180 + 5·col + 2,5`; latitud central `80 − 5·fila − 2,5`.
- La tabla de abajo lista, por fila, los rangos de columnas `[desde, hasta]` (inclusive) con tierra.
- Es una máscara **estilizada**, no cartográfica. Suficiente para la estética; no apta para medir.

```dart
/// fila -> rangos [col inicial, col final] con tierra. 5º por celda.
const kLandMask = <int, List<List<int>>>{
  0: [[21, 32], [39, 40], [55, 56]],
  1: [[9, 19], [21, 33], [49, 50], [54, 71]],
  2: [[2, 22], [23, 31], [37, 71]],
  3: [[2, 16], [20, 24], [26, 28], [31, 32], [37, 71]],
  4: [[3, 16], [21, 24], [35, 35], [38, 71]],
  5: [[4, 16], [20, 25], [34, 35], [36, 71]],
  6: [[5, 25], [35, 71]],
  7: [[10, 25], [34, 40], [45, 64]],
  8: [[11, 24], [34, 37], [38, 38], [41, 64]],
  9: [[12, 23], [34, 63]],
  10: [[13, 20], [33, 63]],
  11: [[12, 18], [20, 21], [33, 49], [50, 62]],
  12: [[16, 19], [21, 23], [33, 47], [45, 48], [50, 53], [55, 58], [60, 60]],
  13: [[17, 19], [20, 24], [33, 46], [47, 47], [51, 52], [55, 57], [60, 60]],
  14: [[18, 19], [20, 26], [33, 47], [52, 52], [55, 56], [57, 59]],
  15: [[20, 29], [36, 46], [55, 56], [57, 59], [60, 61], [63, 65]],
  16: [[20, 29], [36, 45], [55, 56], [57, 59], [62, 66]],
  17: [[20, 30], [37, 44], [56, 58], [63, 66]],
  18: [[21, 30], [37, 44], [57, 60], [62, 64]],
  19: [[22, 30], [38, 45], [59, 66]],
  20: [[22, 28], [38, 45], [58, 66]],
  21: [[22, 28], [38, 43], [58, 66]],
  22: [[22, 27], [39, 43], [59, 66]],
  23: [[22, 26], [60, 66], [69, 70]],
  24: [[22, 26], [65, 65], [69, 70]],
  25: [[22, 25], [69, 70]],
  26: [[22, 25]],
};
```

Aspecto por punto: diámetro 5 px (plano escritorio), 6–7 px (móvil); opacidad `0,45 + ((col*7 + fila*13) % 6) / 10`.

Esta tabla tiene **~650 puntos**: en Flutter se dibuja con **un solo `CustomPainter`** (nunca un widget por punto).

## 2. Mapa plano 2D

### 2.1 Proyección de la escena
Lienzo lógico de la escena: **1440 × 540 px** (lat 80 → −55).

```
x = (lon + 180) * 4
y = (80 - lat) * 4            // + desplazamiento vertical según el contenedor
```

Desplazamiento vertical de la escena dentro del contenedor: 180 px (pantallas de 900), 40 px (banda del expediente de 620), 0 (móvil).

### 2.2 Cámara
Se anima un único `Matrix4`: `translate(tx, ty) · scale(k)` con `origin (0,0)`.

| Vista | k | Centrado en |
| --- | --- | --- |
| **Mundo** | 1 (escritorio: 1 + tx=ty=0) · 0,42 (banda móvil) · 0,62 (mapa móvil) | todo el archivo |
| **Caso** | 3,4 (escritorio) · 2,2 (móvil) | el caso enfocado, desplazado a `(900, 310)` en la banda del expediente |
| **Conexiones** | `clamp(1,2..3 ; 820/(bw+240), 420/(bh+220))` | centro del rectángulo que contiene al caso y sus conectados → `(860, 310)` |

- `tx = destinoX − k·cx`, `ty = destinoY − k·cy`.
- Curva `ease.fly`, **1700–1900 ms**.
- En el mapa explorar de escritorio: `k = clamp(1,4 ; 3,2 ; 900/(bw+260), 560/(bh+260))`, destino `(520, 470)` (deja espacio a la ficha de la derecha).
- En el mapa móvil: `k = clamp(0,6 ; 2,4 ; 340/(bw+120), 260/(bh+120))`, destino `(195, 235)`.

### 2.3 Marcadores
Contraescala `1/k` para que conserven tamaño en pantalla cuando la cámara hace zoom.

| Estado | Diámetro | Extras |
| --- | --- | --- |
| Normal | 12 (14 móvil) | borde 2 px `bg.base`, brillo 12 px del color |
| Seleccionado | 18 (20 móvil) | brillo 26 px, pulso 1,8 s |
| Relacionado | 12 | borde dorado `#F0C674` + etiqueta con el nombre |

- Pulso: anillo del mismo color que escala 0,5 → 2,8 y se desvanece; retraso `(i·0,41) mod 3` s.
- Opacidad: visible = 1; con selección y no relacionado = 0,4; fuera de filtro = 0,12; posterior al año de la línea de tiempo = 0 (sin eventos).
- Zona táctil mínima 44×44 (`Semantics(button: true, label: nombre)`).

### 2.4 Arcos de conexión
Curva cuadrática entre los dos casos: punto de control `(mx, min(ay, by) − dist·0,28 − 20)`.
Trazo dorado `#F0C674`, 1,8 px (**ancho constante**, no escala con la cámara), discontinuo 7/7, desplazamiento animado (1,2 s lineal). Aparece con opacidad tras 600 ms de retraso.
**Etiqueta de relación** en el punto medio de la curva (`0,25·ay + 0,5·cy + 0,25·by`): píldora mono 12 px dorada sobre cristal; solo en la vista *Conexiones*.

Pares (datos): hoy están en `lib/features/cases/data/case_connections_seed.dart` (7 pares). El diseño usa, p. ej.: Zodiac↔Golden State Killer «Norte de California»; Zodiac↔Jack el Destripador «Sin identificar · desafió a la prensa»; La mujer de Isdal↔El hombre de Somerton «Cuerpo sin identificar durante décadas».

### 2.5 Línea de tiempo
- Rango 1888–2025. Un caso es visible si `año ≤ valor`.
- Marcas bajo el deslizador en `((año − 1888)/137)·100 %` con el color de categoría; las futuras a opacidad 0,3.
- Reproducir: `+2` años cada 70 ms; al llegar a 2025 se detiene; si se pulsa estando en 2025, reinicia en 1888.

## 3. Globo 3D

Esfera de puntos con perspectiva. **Decisión de implementación pendiente** (ver `flutter-implementation.md` §3); la especificación visual y matemática es la siguiente.

### 3.1 Geometría
- Radio `R = 400` (unidades de diseño), perspectiva `P = 2200`.
- Cada punto de tierra y cada marcador se sitúa en `(lat, lon)`:
  ```
  p0 = R' · ( cosφ·sinλ ,  −sinφ ,  cosφ·cosλ )        // x derecha, y abajo, z hacia el observador
  ```
  con `φ = lat`, `λ = lon`, y `R' = R` (tierra), `R + 3` (marcadores), `R + 4 + sin(πt)·Ω·70` (arcos).
- Tamaño del punto de tierra: `max(3,2 ; 6,4·cos(lat) + 0,8)` px (se estrecha hacia los polos).
- **Caras traseras ocultas.** Un punto es visible si `z' > 0` tras rotar.

### 3.2 Orientación de la cámara
Rotación del globo = `rotX(gx) · rotY(gy)` con `gx = −lat_objetivo`, `gy = −lon_objetivo` → el objetivo queda **de frente**.
Desenrollar `gy` para girar por el camino corto: `gy = objetivo + 360·round((actual − objetivo)/360)`.

Proyección a pantalla de un punto (para etiquetas 2D):
```
x1 =  p.x·cos(gy) + p.z·sin(gy)
z1 = −p.x·sin(gy) + p.z·cos(gy)
y2 =  p.y·cos(gx) − z1·sin(gx)
z2 =  p.y·sin(gx) + z1·cos(gx)
f  =  P / (P − s·z2)
X  =  cx + s·x1·f ,  Y = cy + s·y2·f        // visible si z2 > 40
```

### 3.3 Modos
| | Centro | Escala `s` | Comportamiento |
| --- | --- | --- | --- |
| **Portada** | (1010, 520) | 1,0 | Gira al caso del slide activo; halo del color de categoría |
| **Explorar** | (640, 455) | 0,78 | Sin selección: deriva `gy −= 0,22°` cada 70 ms (tras terminar el vuelo). Con selección: gira al caso |

Giro y cambio de escala/centro: **1900 ms** `ease.globe` (la deriva usa transición lineal corta de 80 ms).

### 3.4 Acabado
- Cuerpo de la esfera (disco 2D bajo los puntos): `radial-gradient(38% 32%, #1A2638, #0A0F18 55%, #05070B)` + borde 1 px `rgba(140,190,240,.2)` + resplandor exterior 150 px `rgba(90,160,208,.22)`.
- Sombreado encima (2D, sin eventos): brillo especular `rgba(140,190,240,.16)` arriba-izquierda y oscurecimiento del borde hasta `rgba(5,7,11,.92)`.
- Halo de color detrás (1500 px): `radialGradient(color_categoría · 0x30 → transparente al 52 %)`, cambia con fundido de 1400 ms.
- Arcos: 27 puntos dorados de 5 px con brillo, aparecen secuencialmente (`900 + k·35` ms).

## 4. Consideraciones de rendimiento (Flutter)

- Un **único `CustomPainter`** para toda la tierra; `RepaintBoundary` separado para marcadores y arcos.
- La máscara se convierte **una vez** a una lista de `Offset` (plano) o de vectores unitarios (globo) y se cachea.
- Globo: proyectar ~650 puntos por fotograma es trivial en CPU; el coste está en compositar, no en calcular.
- Evitar `Opacity`/`BackdropFilter` dentro de la escena animada; el cristal solo en fichas estáticas.
- Con `MediaQuery.disableAnimations`, cortar cámara sin transición y detener pulsos y deriva.
