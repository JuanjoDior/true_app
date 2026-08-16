---
name: true-app-tests-verdes-no-prueban
description: "Los tres defectos de producción de true_app que 472 tests en verde no vieron, y qué helper de flutter_test tapó cada uno"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 37c724e9-e9a5-43a0-92bd-d84b54438879
  modified: 2026-08-14T19:47:47.857Z
---

En true_app, una suite verde nunca ha bastado. Del ciclo `case-publication-detail`
(agosto 2026) salieron **tres defectos de producción y ninguno lo cazó la suite**:

1. **`onMapReady` no significa "en pantalla".** Se dispara con el mapa offstage —
   la Sala tapada por la ruta de un expediente — pero el visor de flutter_map sólo
   se inicializa al pintarse. Mover la cámara ahí revienta con
   `LateInitializationError` y **cualquier enlace directo fallaba**. La guarda
   tiene que exigir tamaño, no sólo el flag `_ready`.
2. **Un parámetro sólo-para-tests que sustituye una entrada real crea un camino
   que ningún test recorre.** `TrueCrimeApp.initialLocation` sembraba un
   `routeInformationProvider` siempre; en producción valía null y la app ignoraba
   la barra de direcciones. **Ningún enlace directo funcionaba** y los 431 tests
   pasaban porque todos pasaban el parámetro.
3. **`SituationTopBar` desbordaba** en varias bandas de ancho, tolerado y
   documentado. Se curó de rebote al subir un umbral.

Y dos tests escritos por mí que **no podían fallar**, cazados por mutación:
`tester.enterText` bombea un frame por dentro, así que no puede probar dos
ediciones sin reconstrucción; y tres aserciones `isEmpty` sobrevivían a borrar la
funcionalidad entera.

**Patrón**: los helpers de alto nivel de `flutter_test` hacen más de lo que
parece, y ese "más" suele ser exactamente la condición adversaria que querías
probar. Ya pasó con [[flutter-scrolluntilvisible-no-prueba-scroll]] y con
[[true-app-tests-no-ven-el-navegador]].

**Reglas que se derivan**: montar al menos un test con la aplicación ENTERA, porque
hay defectos que sólo existen en la composición; registrar en `tasks.md` qué mató
cada sonda de mutación; y si el nombre de un test promete una condición, verificar
con una mutación que esa condición se reproduce de verdad — o cambiar el nombre.
