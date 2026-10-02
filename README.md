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

Para pasar la suite: `flutter test`.

## Las dos mitades

| Pantalla | Para quién | Qué hace |
|----------|------------|----------|
| **Sala de Situación** | Cualquiera | Mapa mundial con los casos, filtros por estado, línea de tiempo y expediente de cada caso |
| **Formulario de alta** | El equipo editorial | Redactar casos nuevos en borradores locales, también sin conexión. El inicio de sesión queda disponible para el futuro envío explícito a revisión |

Al formulario se entra por el `+` del rail izquierdo.

## Cómo se publica un caso

El catálogo publicado vive en **Supabase** (tabla `cases`) y la web lo lee al
abrirse, así que publicar un caso no requiere commit ni despliegue.

El circuito de revisión está en construcción (`odd/tasks/case-review-publish.md`):
quien redacta podrá enviar un borrador con «Enviar a revisión» y el revisor lo
aprobará; al aprobarlo aparece en la web al momento. El contenido no se envía al
iniciar sesión ni se sincroniza en segundo plano. Un envío sin conexión o fallido
requerirá que quien redacta lo reintente expresamente. El servicio de envío
(`DraftSubmissionService`) ya está listo, pero aún sin interfaz, y nunca reintenta
en segundo plano. Las reglas de acceso de
`supabase/migrations/` son lo único que protege los datos: la clave del
navegador es pública por diseño.

Los borradores se guardan localmente en cada dispositivo (`localStorage` en el
navegador y almacenamiento local de preferencias en Windows). Los borradores
antiguos del navegador siguen allí; para llevarlos a Windows se usa una copia
de seguridad por fichero y se importa en la aplicación. No hay transferencia
automática entre dispositivos.

### Windows

La compilación local de Windows sirve como verificación técnica: no instala ni
distribuye la aplicación. La instalación, el canal de actualizaciones y el
paquete para Iván siguen pendientes de la decisión de entrega CRP-08. El
selector nativo de ficheros para exportar e importar copias debe probarse en el
Windows de destino antes de la entrega.

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
