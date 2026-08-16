---
name: flutter-scrolluntilvisible-no-prueba-scroll
description: "tester.scrollUntilVisible no prueba que se pueda hacer scroll en un SingleChildScrollView: se salta la física y pasa en verde con el scroll muerto"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 37c724e9-e9a5-43a0-92bd-d84b54438879
  modified: 2026-08-12T18:56:50.950Z
---

En Flutter (comprobado en 3.44.0), `tester.scrollUntilVisible` **no demuestra
que el usuario pueda desplazarse**. En `packages/flutter_test/lib/src/controller.dart`:

- línea 2471: `while (maxIteration > 0 && finder.evaluate().isEmpty)` — sólo
  arrastra mientras el finder no encuentra nada.
- línea 2482: `await Scrollable.ensureVisible(element(finder));`

Un `SingleChildScrollView` construye todos sus hijos de golpe (no es lazy como
`ListView`), así que el finder nunca está vacío: **cero gestos de arrastre**, y
todo el movimiento sale de `ensureVisible`, que es programático y no pasa por
`ScrollPhysics`. Un formulario con `NeverScrollableScrollPhysics` deja el test
en verde.

Para probar alcance por scroll de verdad:

1. Precondición no vacua: `position.maxScrollExtent > 0` y la última sección
   fuera de la ventana al arrancar. Sin eso, "alcanzable" se cumple sola.
2. Arrastrar con `tester.dragFrom(...)`, que sí pasa por la física.
3. Arrastrar sobre el margen del scroll (fuera del padding): dentro viven mapas
   y campos que se quedan con el gesto.
4. Si varias secciones entran en el mismo frame, apuntarlas por su `top` real y
   no por el orden esperado, o la aserción de orden no puede fallar entre
   vecinas.

Es otra instancia de la trampa de siempre en este proyecto: una aserción que no
puede fallar. Ver [[true-app-tests-no-ven-el-navegador]].
