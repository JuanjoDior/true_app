# true_app — contexto del proyecto

Este documento es para quien llega al proyecto y necesita entender **por qué**
está hecho así, no sólo cómo. Para arrancarlo, el `README.md`.

Última revisión: **3 de agosto de 2026**.

## Qué es

Un archivo de casos reales de true crime, con vocación editorial: nada de
morbo, las víctimas se nombran con respeto y cada caso cita sus fuentes.

El producto tiene dos caras:

- La **Sala de Situación**, pública: un mapa mundial oscuro donde cada caso es
  un punto, con filtros por estado de investigación, línea de tiempo del archivo
  y el expediente de cada caso.
- El **formulario de alta**, interno: donde se redactan los casos nuevos y se
  exportan al catálogo.

## Decisiones de producto

| Decisión | Por qué |
|----------|---------|
| Sin backend ni CMS | El catálogo es un JSON versionado. Nada entra sin pasar por un commit, y eso es la revisión editorial |
| El mapa es la navegación | Un caso sin coordenadas no existe en el producto. Por eso la ubicación es obligatoria para publicar |
| Un tipo por caso | Taxonomía cerrada: asesinatos aislados, asesinos en serie, secuestros y casos sin resolver. Los tags acompañan, no sustituyen |
| Los borradores no se versionan | Viven en el navegador de quien escribe. El repositorio sólo guarda lo publicado |
| El acceso al formulario es un filtro, no seguridad | Una clave compartida en el código. Evita entradas accidentales; no protege de nada más |

## El circuito de publicación

```
Formulario  ──►  Copiar JSON  ──►  assets/data/cases.json  ──►  commit  ──►  Pages
(navegador)      (portapapeles)     (repositorio)                            (público)
```

El paso manual del portapapeles es deliberado. Automatizarlo significaría montar
un backend, y con el volumen actual el coste no compensa.

**Cuándo revisar esta decisión:** cuando llegue un lote de diez casos de golpe.
Copiar y pegar de uno en uno deja de tener gracia ahí.

## Qué captura el formulario

| Sección | Campos | Obligatorio |
|---------|--------|-------------|
| Datos básicos | Título, categoría, año, estado | Sí |
| Ubicación | Se marca en el mapa; país, ISO y municipio se rellenan solos | Sí |
| Resumen y ficha | Resumen, víctimas, tags | No |
| Cronología | Hitos con fecha, qué ocurrió y tipo | No |
| Enlaces | Fuentes externas tipadas | No |
| Fotografías | Imágenes ya alojadas, por URL | No |

Lo obligatorio es lo que el catálogo no admite vacío. El resto enriquece la
ficha pero no bloquea.

**Lo que todavía no captura:** `featuredRank` y `relevanceRank`, que deciden qué
caso sale destacado y en qué orden aparece. Hoy se editan a mano en el asset.

## Cómo está montado

Arquitectura por capas dentro de cada feature:

```
domain/       los modelos y sus reglas, sin dependencias de Flutter
data/         de dónde salen los datos (asset JSON, localStorage, Nominatim)
application/  providers de Riverpod, validación y exportador
presentation/ los widgets
```

Tres piezas que conviene conocer antes de tocar nada:

- **`CaseDossierPanel`** pinta el expediente, y lo reutiliza la previsualización
  del formulario. Si el preview necesita mostrar algo nuevo, primero hay que
  preguntarse si el expediente publicado debería mostrarlo también: casi siempre
  la respuesta es sí, y entonces sale gratis en los dos sitios.
- **`CaseDraftsNotifier.editDraft`** recibe una función de transformación, no un
  borrador ya construido. Es lo que evita que dos campos editados seguidos se
  pisen entre sí.
- **`case_exporter.dart`** es el único puente entre el borrador y el catálogo.
  Su contrato real es que lo que emite vuelva a entrar por
  `TrueCrimeCase.fromJson` sin perder nada.

## Trampas conocidas

- **`pumpAndSettle` no sirve** con nada animado de este proyecto. Ni con el
  ticker de la home ni con el mapa: `flutter_map` no dispara su `onTap` en tests
  con `pumpAndSettle`. Usar `tester.pump(Duration(milliseconds: 400))`.
- **`copyWith` no borra.** Sigue el patrón `valor ?? this.valor`, así que pasar
  `null` conserva lo anterior. Para asentar un grupo de campos que vienen de la
  misma fuente hace falta un método explícito, como `withResolvedPlace`.
- **Los tests con `pump()` entre pulsaciones ocultan carreras.** El bug más caro
  del proyecto (pérdida silenciosa de datos al escribir rápido) pasó por delante
  de 45 tests en verde. Apareció al usar la app de verdad en el navegador.
- En **Git Bash**, anteponer `MSYS_NO_PATHCONV=1` a los comandos con rutas que
  empiezan por `/`.

## Pendiente

| Qué | Estado |
|-----|--------|
| El formulario sólo funciona en escritorio | Es un `Row` de anchos fijos con el mapa dentro. Depende de si se van a cargar casos desde el móvil |
| `featuredRank` y `relevanceRank` | Edición manual en el asset |
| Error en consola al arrancar | `updates_ticker.dart:46`, sin efecto visible |

## Convenciones

- Commits en castellano, formato convencional, sin atribución a IA.
- Comentarios de código en castellano; explican el porqué, no el qué.
- La interfaz, en castellano.
- Los tests describen comportamiento, no implementación.
