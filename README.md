# true_app

Archivo de casos reales de true crime, en Flutter web. El mapa es el centro:
cada caso es un punto, y desde ahí se abre su expediente con cronología, fuentes
y fotografías.

Publicado en **https://juanjodior.github.io/true_app/**

## Arrancar

```bash
flutter pub get
flutter run -d chrome
```

Para pasar la suite: `flutter test` (19 archivos, 124 tests).

## Las dos mitades

| Pantalla | Para quién | Qué hace |
|----------|------------|----------|
| **Sala de Situación** | Cualquiera | Mapa mundial con los casos, filtros por estado, línea de tiempo y expediente de cada caso |
| **Formulario de alta** | El equipo editorial | Redactar casos nuevos y exportarlos al catálogo. Detrás de una clave compartida |

Al formulario se entra por el `+` del rail izquierdo.

## Cómo se publica un caso

No hay backend ni CMS: el catálogo es un archivo JSON versionado. El circuito es
manual a propósito, para que nada entre sin pasar por una revisión.

1. En el formulario, rellenar el caso. La ubicación se marca **tocando el mapa**:
   país y municipio se rellenan solos.
2. Pulsar **Copiar JSON**. Sólo se activa cuando el borrador está completo.
3. Pegar el objeto en `assets/data/cases.json`.
4. Commit y push. El despliegue es automático.

Los borradores viven en el navegador de quien los escribe (`localStorage`), no en
el repositorio.

## Estructura

```
lib/
├── app/                    shell de la aplicación
├── core/                   tema, tokens y configuración del mapa
└── features/
    ├── cases/
    │   ├── domain/         el caso, el borrador y sus piezas
    │   ├── data/           catálogo JSON, borradores y geocodificación
    │   ├── application/    providers, validación y exportador
    │   └── presentation/   formulario de alta
    └── home/               Sala de Situación
```

`assets/data/cases.json` es el catálogo publicado: **14 casos** curados.

## Despliegue

`.github/workflows/deploy-pages.yml` pasa los tests, compila y publica en GitHub
Pages en cada push a `main`. Si los tests fallan, no se despliega.

## Más contexto

`PROJECT_CONTEXT.md` recoge las decisiones de producto, por qué el catálogo es un
JSON y qué queda pendiente.
