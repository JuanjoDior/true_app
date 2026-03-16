# true_app

Web app Flutter orientada a descubrir casos reales de true crime mediante un mapa mundial, una cartelera editorial y fichas con fuentes e ideas de escucha relacionadas.

## Primeros pasos

```bash
flutter pub get
flutter run
```

## Estructura principal

- `lib/app/`: shell principal de la aplicacion.
- `lib/core/`: tema, tokens y configuracion del mapa.
- `lib/features/cases/`: dominio, datos JSON locales y servicios de busqueda.
- `lib/features/home/`: home, header, cartelera, mapa y ficha responsive.
- `assets/data/cases.json`: catalogo curado inicial de casos reales.
- `test/`: parseo de datos, busqueda, layout y responsive.

## Fase 1 implementada

- Header fijo con buscador y acceso a cartelera.
- Cartelera editorial de casos destacados.
- Mapa mundial interactivo con marcadores.
- Panel lateral en desktop y sheet inferior en movil.
- Fuentes visibles separadas en investigacion y podcast.

## GitHub Pages

- Repositorio: `https://github.com/JuanjoDior/true_app`
- URL esperada de despliegue: `https://JuanjoDior.github.io/true_app/`
- El workflow de despliegue está en `.github/workflows/deploy-pages.yml`
