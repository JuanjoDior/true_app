# true_app - Contexto del proyecto

## Resumen

`true_app` es una web en Flutter orientada a convertirse en una especie de "Netflix del true crime".
La idea base es que el usuario descubra casos reales mediante un mapa mundial, filtros por tipo de caso,
una capa editorial de destacados y fichas con contexto, investigación y podcasts relacionados.

La app ya no es una plantilla vacía. Tiene una base visual y técnica seria, pero el catálogo público
se ha reiniciado a propósito para empezar desde cero con datos bien pensados.

## Estado actual de la app

Ahora mismo la app está en una fase de base estructural:

- Hay `header` fijo con buscador.
- Hay un `rail` superior reservado para futuros casos destacados.
- Hay `filtros por tipo` encima del mapa.
- Hay `mapa mundial` preparado para mostrar casos.
- Hay `panel de detalle` responsive para cuando existan casos seleccionados.
- El catálogo público de producción está vacío a propósito.

Esto significa que la app ya comunica la estructura del producto, pero todavía no publica casos reales.

## Decisiones de producto ya tomadas

### Enfoque general

- Plataforma inicial: Flutter web.
- Hosting: GitHub Pages.
- Estilo visual: editorial, oscuro, serio, cinematográfico.
- Mapa como centro de navegación.
- Estado inicial sin backend ni CMS.
- Datos locales en JSON mientras se diseña la base del producto.

### Tipología de casos

Cada caso tendrá un único tipo principal. La taxonomía actual cerrada es:

- `Asesinatos aislados`
- `Asesinos en serie`
- `Secuestros`
- `Casos sin resolver`

Los `tags` siguen existiendo, pero ya no sustituyen a la categoría principal.

### Datos públicos

- Se eliminaron los ejemplos reales que había en la app.
- `assets/data/cases.json` ahora contiene `[]`.
- La app de producción arranca sin seed data pública.
- Los casos de ejemplo solo existen en `test/` para validar UI y lógica.

## Qué se hizo antes de esta limpieza

Antes de la limpieza se construyó una primera fase funcional con:

- shell completa de app Flutter
- tema editorial personalizado
- mapa con `flutter_map`
- búsqueda
- cartelera editorial
- panel lateral / sheet móvil
- fuentes separadas en investigación y podcast
- despliegue en GitHub Pages

Después se decidió limpiar esa primera versión para no arrastrar ejemplos reales provisionales y dejar
una base más controlada para crecer correctamente.

## Qué se ha cambiado en esta iteración

### Dominio

Se añadió un enum de categorías:

- `lib/features/cases/domain/case_category.dart`

Se amplió el modelo principal:

- `lib/features/cases/domain/true_crime_case.dart`

Cambios relevantes del modelo:

- nuevo campo `category`
- `featuredRank` ahora es opcional
- `relevanceRank` ahora es opcional

### Presentación de categorías

Se creó un mapper visual para centralizar textos y colores:

- `lib/features/cases/presentation/case_category_presentation.dart`

Este archivo define:

- `label`
- `shortLabel`
- `description`
- `color`

para cada tipo de caso.

### Estado y providers

Se actualizaron los providers en:

- `lib/features/cases/application/cases_providers.dart`

Providers importantes:

- `casesRepositoryProvider`
- `casesProvider`
- `searchQueryProvider`
- `activeCategoryProvider`
- `featuredCasesProvider`
- `filteredCasesProvider`
- `relevantSuggestionsProvider`
- `categoryCountsProvider`
- `emptyCatalogProvider`
- `selectedCaseIdProvider`
- `selectedCaseProvider`

### Búsqueda

La lógica está en:

- `lib/features/cases/application/case_search_service.dart`

La búsqueda actual puede mirar:

- título
- país
- ciudad o región
- tags
- nombre de categoría
- términos asociados a categoría

Además ya soporta:

- orden por relevancia
- destacados
- conteo por categoría

### Home actual

La home principal está en:

- `lib/features/home/presentation/home_page.dart`

Se reorganizó para que quede así:

1. `Header`
2. `Rail de futuros destacados`
3. `Bloque de mapa`
4. `Barra de filtros por tipo`
5. `Mapa`
6. `Ficha de caso` si hay selección

### Widgets clave

- `lib/features/home/presentation/widgets/home_header.dart`
  - buscador
  - mensaje de catálogo en preparación
  - botón de acceso al mapa

- `lib/features/home/presentation/widgets/featured_case_rail.dart`
  - soporta estado vacío
  - muestra placeholders editoriales si no hay destacados

- `lib/features/home/presentation/widgets/case_type_filter_bar.dart`
  - chips por categoría
  - contadores
  - selección de filtro

- `lib/features/home/presentation/widgets/case_world_map.dart`
  - mapa base
  - marcadores
  - overlay de empty state
  - leyenda por tipo

- `lib/features/home/presentation/widgets/case_detail_panel.dart`
  - ficha del caso
  - chip de categoría
  - secciones de investigación y podcast

- `lib/features/home/presentation/widgets/case_featured_card.dart`
  - tarjeta de destacado preparada para el futuro catálogo

## Estado visual y UX actual

### Header

El header mantiene buscador y branding, pero ahora comunica que el catálogo aún no está cargado.

Mensaje actual:

`El catálogo aún no está cargado. Estamos preparando la primera selección de casos.`

### Rail superior

No muestra casos reales.
Se usa como espacio reservado para futuros casos destacados.

### Filtros por tipo

Siempre se muestran, aunque el conteo sea cero.
Esto enseña la estructura futura de la app incluso sin datos cargados.

### Mapa

Si no hay casos:

- no hay marcadores
- se mantiene el mapa base
- aparece un empty state editorial
- aparece leyenda de tipos

### Panel de detalle

Solo aparece cuando hay un caso seleccionado.
No se muestra un panel vacío artificial cuando no hay datos.

## Paleta actual por categorías

- `Asesinatos aislados`: rojo oscuro sobrio
- `Asesinos en serie`: carmesí profundo
- `Secuestros`: ámbar apagado
- `Casos sin resolver`: gris azulado frío

Los marcadores del mapa comparten forma y cambian por color según la categoría.

## Estructura principal del proyecto

### Código

- `lib/app/`
  - shell principal de la app

- `lib/core/`
  - tema
  - configuración visual
  - configuración del mapa

- `lib/features/cases/`
  - dominio
  - datos
  - aplicación
  - presentación auxiliar

- `lib/features/home/`
  - página principal
  - widgets de home

- `lib/shared/`
  - widgets reutilizables simples

### Datos y assets

- `assets/data/cases.json`
  - catálogo público actual

- `assets/fonts/`
  - tipografías locales

## Tests y validación

Hay tests para:

- parseo de JSON
- búsqueda
- conteo por categoría
- orden por relevancia/destacados
- render de la home vacía
- filtros por tipo
- apertura de detalle
- responsive móvil

Archivos relevantes:

- `test/local_cases_repository_test.dart`
- `test/case_search_service_test.dart`
- `test/widget_test.dart`
- `test/test_support/sample_cases.dart`

Última validación local realizada:

- `flutter analyze` OK
- `flutter test` OK
- `flutter build web --release --base-href /true_app/` OK

## Despliegue

Repositorio:

- `https://github.com/JuanjoDior/true_app.git`

Workflow de Pages:

- `.github/workflows/deploy-pages.yml`

URL prevista pública:

- `https://juanjodior.github.io/true_app/`

## Commits importantes recientes

- `745e8ac` - `Implement true crime discovery home`
- `7a97b19` - `Clean home and add case categories`

## Qué debería saber otro chat antes de continuar

1. La app ya tiene base técnica suficiente para crecer sin rehacer estructura.
2. No hay que volver a meter ejemplos improvisados en producción.
3. La siguiente fase natural es empezar a cargar casos reales bien curados por categoría.
4. Si se añaden casos nuevos, deben usar el modelo con `category` y no depender solo de `tags`.
5. El mapa debe seguir siendo el núcleo visual del producto.
6. La cartelera seguirá existiendo, pero solo debería poblarse cuando haya destacados reales.

## Próximos pasos razonables

Opciones lógicas para continuar:

- cargar el primer lote real de casos
- mejorar la UI del rail vacío para que tenga más carácter editorial
- añadir filtros combinados por país o región
- introducir deep links por caso
- preparar configuración real del proveedor de tiles para producción
- diseñar una ficha más rica con timeline o metadatos editoriales

## Nota importante

El `README.md` todavía refleja parcialmente la etapa anterior y conviene actualizarlo en una próxima iteración
para alinearlo con el estado actual de catálogo vacío + categorías + mapa preparado.

## Convención de idioma

A partir de este punto:

- los mensajes de commit deben escribirse en castellano
- los comentarios que se añadan en el código deben escribirse en castellano
- la comunicación técnica del proyecto debe mantenerse en castellano salvo que haya una razón concreta para no hacerlo
