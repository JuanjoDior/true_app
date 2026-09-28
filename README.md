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

Para pasar la suite: `flutter test` (52 archivos, 554 tests).

## Las dos mitades

| Pantalla | Para quién | Qué hace |
|----------|------------|----------|
| **Sala de Situación** | Cualquiera | Mapa mundial con los casos, filtros por estado, línea de tiempo y expediente de cada caso |
| **Formulario de alta** | El equipo editorial | Redactar casos nuevos como borradores. Hay que entrar con una cuenta (email y contraseña) |

Al formulario se entra por el `+` del rail izquierdo.

## Cómo se publica un caso

El catálogo publicado vive en **Supabase** (tabla `cases`) y la web lo lee al
abrirse, así que publicar un caso no requiere commit ni despliegue.

El circuito de revisión está en construcción (`odd/tasks/case-review-publish.md`):
quien redacta envía el borrador a revisión y el revisor lo aprueba; al aprobarlo
aparece en la web al momento. Las reglas de acceso de
`supabase/migrations/` son lo único que protege los datos: la clave del
navegador es pública por diseño.

Los borradores viven de momento en el navegador de quien los escribe
(`localStorage`); pasarán a Supabase con el circuito de revisión.

## Estructura

```
lib/
├── app/                    shell de la aplicación
├── core/                   tema, tokens y configuración del mapa
└── features/
    ├── cases/
    │   ├── domain/         el caso, el borrador y sus piezas
    │   ├── data/           catálogo en Supabase, borradores y geocodificación
    │   ├── application/    providers, validación y exportador
    │   └── presentation/   formulario de alta
    └── home/               Sala de Situación
```

La carga inicial del catálogo (16 casos) está en
`supabase/migrations/20260927110000_seed_cases.sql`; `supabase/tests/` prueba
las reglas de acceso con `supabase test db`.

## Despliegue

`.github/workflows/deploy-pages.yml` pasa los tests, compila y publica en GitHub
Pages en cada push a `main`. Si los tests fallan, no se despliega.

## Más contexto

`PROJECT_CONTEXT.md` recoge las decisiones de producto, por qué el catálogo pasó
de un JSON a Supabase y qué queda pendiente.
