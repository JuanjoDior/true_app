---
name: true-app-tests-no-ven-el-navegador
description: "En true_app ningún widget test puede ver el navegador, y esa ceguera ya costó dos bugs en producción"
metadata: 
  node_type: memory
  type: project
  originSessionId: 18c09f95-7afd-469f-b576-a604d54459fe
  modified: 2026-08-12T09:38:49.083Z
---

En `true_app` (Flutter web) **ningún widget test puede observar el navegador**.
`tester.view.physicalSize` inyecta el tamaño directamente y salta por encima de
la negociación de viewport, así que la suite entera puede estar verde mientras
el sitio publicado se comporta de otra manera.

Ya costó dos veces:

1. La pérdida silenciosa de datos al escribir rápido pasó por delante de 45
   tests en verde y apareció usando la app de verdad en el navegador.
2. En agosto de 2026, 165 tests responsive verificados por mutación estaban
   verdes mientras el sitio renderizaba el layout de escritorio en un teléfono:
   a `web/index.html` le faltaba el `<meta name="viewport">`.

Regla que se deriva: **una precondición que vive en el documento anfitrión se
verifica leyendo el documento**, no montando un árbol de widgets. El guard está
en `test/web_index_viewport_test.dart`.

Corolario, y es el que más vale: **un test verde no prueba nada por sí solo**.
Cuatro rondas de verificación de un mismo ciclo encontraron cuatro veces el
mismo defecto — una aserción que no podía fallar. Muestrear anchos alrededor de
un umbral lo acota a un rango pero nunca fija su valor. Dos `expect` dentro de
un mismo `test` abortan en el primero, así que una mutación combinada sólo
demuestra que la primera está viva; hay que separarlos y mutar de a uno. Lo
único que demuestra que un test sirve es verlo fallar.

Está todo en `PROJECT_CONTEXT.md` → "Trampas conocidas".

Ver también [[true-app-handoff-agosto-2026]].
