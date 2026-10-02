# Entrega USB para Iván

## Objetivo y alcance
Preparar una carpeta copiable a USB para usar la aplicación actual en Windows 10/11 x64 sin herramientas de desarrollo. El usuario confirmó ese sistema. Incluir todos los archivos de Release e instrucciones en castellano. No implementar nuevas funciones, cambiar fuentes, publicar, instalar software en este equipo ni hacer commits sin autorización explícita. Preservar todos los cambios existentes de case-review-publish.

## Plan y comprobaciones
- [x] USB-01: Compilar Release desde el estado local actual y comprobar analyze y tests. Ruta delegada a gentle-ai-worker. Analyze exit 0 sin incidencias; 636 tests aprobados; build windows Release exit 0. Fuentes y estado git preexistente preservados. Sin commit solicitado.
- [x] USB-02: Preparar build/entrega-ivan/TrueApp-Ivan con Release completo, instrucciones y requisito Visual C++ resuelto o explicado; verificar contenido y arranque local de forma independiente. Worker empaquetó; gentle-ai-verify confirmó 22/22 archivos iguales por SHA256, firma Microsoft Valid, analyze limpio y arranque con ventana durante 15 segundos, cierre limpio exit 0. Sin commit solicitado. El arranque y selector de archivos en el equipo de Iván quedan pendientes hasta probar allí.

## Restricciones y aceptación
La carpeta debe incluir true_app.exe, DLLs y data íntegros. No entregar solo el EXE ni el Debug. Internet necesario para catálogo e inicio de sesión; borradores locales no viajan: exportar/importar por fichero. No prometer envío a revisión, instalación automática ni actualizaciones. Cualquier redistribuible descargado debe provenir de Microsoft y comprobar su firma antes de incluirlo; no ejecutarlo aquí.

TDD: no aplica a empaquetado de artefactos, sin cambios de comportamiento autorizados. Comprobaciones ordinarias: flutter analyze --no-pub; flutter test --no-pub; flutter build windows --release --no-pub, inspección de paquete y arranque local. No se configura TDD por la mera presencia de tests.

## Progreso
USB-01 y USB-02 completados: paquete preparado y verificado localmente. Rama existente: case-review-publish. Fuentes y tests sucios preexistentes preservados.
Paquete: build/entrega-ivan/TrueApp-Ivan; 24 archivos, 61.638.065 bytes. 22/22 archivos Release idénticos por SHA256, más LEEME.txt y Requisitos/vc_redist.x64.exe. Redistribuible descargado de https://aka.ms/vs/17/release/vc_redist.x64.exe; Authenticode Valid, firmante Microsoft Corporation; no ejecutado. EXE conserva fecha previa por compilación incremental; data/app.so de 7.685.008 bytes compilado el 30/09/2026 17:52 y hash idéntico en paquete. Verificación independiente de arranque: ventana true_app, proceso respondió durante 15 segundos y cerró limpiamente. No se verificó usabilidad visual, catálogo, login ni selector.
Entrega: carpeta local, no publicación. Previsión de líneas authored: menos de 100 (seguimiento/instrucciones), artefactos generados excluidos; estrategia ask-on-risk. Commits omitidos: usuario no los pidió. Revisión nativa de fuentes no aplica mientras no se cambien fuentes: solo empaquetado generado y documentación pasiva.

## Siguiente paso
Copiar la carpeta completa al USB y luego al disco de Iván; abrir true_app.exe. Si falta el runtime, instalar Requisitos/vc_redist.x64.exe. Exportar borradores aparte antes del viaje si se necesitan. Pendiente en destino: apertura y usabilidad, catálogo/login con internet y exportación/importación mediante selector nativo. No requiere herramientas de desarrollo; no tiene entrega a revisión ni actualizaciones automáticas.
