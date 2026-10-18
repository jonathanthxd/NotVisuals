# NotVisuals v8 — candidata 2: informe de implementación

## 1. Estado general

Continuación de `33fafc579658d20ece13066e4f546b533e5f5a08` en
`feat/v8-ink-and-light`, PR #1. Se conserva v7 en `main` y la primera candidata
local en `dist/NotVisuals_26.3_v8_candidate.zip`. No se publica release, no se
fusiona y no se modifica Modrinth.

**Entrega parcial experimental:** hay código integrado, compilación GLSL y
pruebas de buffers sintéticos; no hay cliente Minecraft accesible ni aceptación
visual de esta candidata. La mejora artística y la corrección del parpadeo
reportado siguen pendientes de verificación en juego.

## 2. Investigación de referencias

Se inspeccionaron los tres ZIP y sus **269 archivos** fuera del checkout.
[Investigación y matriz técnica](V8_REFERENCE_RESEARCH.md),
[inventario completo con hashes](V8_REFERENCE_INVENTORY.csv).

- **So Tuff:** capas y planos luminosos, `shade:false`, AO y animaciones.
  Aportó la necesidad de distinguir núcleos pequeños de superficies extensas.
  No se copió ningún modelo ni textura; no se simula emisión física con shade.
- **Fog:** curvas de distancia y transiciones. Se usa una curva monotónica
  original en el cielo, sin reemplazar el include global de niebla ni añadir Sodium.
- **Shaders experimental:** profundidad de capas, soporte de vecinos, dispersión
  de highlights y lightmap. No se reutilizaron código GLSL, near/far arbitrarios,
  transparencia antigua, codificación RGB de depth ni control de skins por colores.
- No se encontró licencia verificable para los adjuntos. Todos se mantienen
  como referencia conceptual, fuera de los assets distribuidos.

Se confirmaron los contratos de 26.3 en el espejo de MC Assets fijado al commit
`f44cf36a295b1ecb0d34516765a44a8b5be10761`. El manifiesto
[V8_RENDERER_CONTRACT.json](V8_RENDERER_CONTRACT.json) contiene rutas y hashes;
los assets Vanilla descargados para pruebas permanecen fuera del repositorio.
La descarga directa de metadatos de Mojang dio 403; el espejo no es una garantía
oficial de estabilidad ni sustituye una carga real de ShaderC.

## 3. Depth Stability

**Investigado / implementado / probado en buffers sintéticos / experimental.**

El shader anterior comparaba cuatro diferencias absolutas de profundidad no
lineal contra un umbral fijo `0.003`. Solo validaba el centro, por lo que una
muestra vecina clear podía crear un borde. No verificaba continuidad de aristas:
un impulso aislado de profundidad pintaba cinco píxeles cian.

Ahora `depth_edges.glsl` usa texelFetch, rechaza valores no finitos y endpoints
en cada pareja, normaliza la diferencia respecto al endpoint de profundidad
más próximo y exige soporte a ambos lados en la dirección tangente. La métrica
es simétrica bajo `z -> 1-z`; **no** es profundidad lineal ni reconstrucción
geométrica. Se excluye el borde exterior de dos texels para evitar wrap/clamp falso.

En el caso sintético del impulso, los píxeles afectados pasan de **5 a 0**;
se preservan aristas continuas y se rechaza jitter pequeño en ocho entradas
sucesivas. No hay historial temporal, máscara rectangular de mano ni colores
usados para disimular errores.

**No confirmado:** cuál de estas causas provoca el parpadeo en la mano real.
Un borde coherente incorrecto puede persistir. El filtro puede omitir esquinas,
geometría de menos de tres píxeles y siluetas que tocan depth clear. No hay ID
de primera persona ni profundidad correcta garantizada para transparencias.
NV-DEPTH-001/002 siguen pendientes de aceptación en Minecraft.

`notvisuals:depth_lab` mantiene su cian diagnóstico y sigue siendo optativo.

## 4. Skyflow

**Implementado / compilado / probado sintéticamente / experimental.**

Nuevo `assets/minecraft/shaders/core/sky.fsh`, conectado por la ruta del renderer
26.3 y usando su vertex Vanilla sin sustituirlo. Lee las distancias y bloques
Fog/DynamicTransforms existentes. Suaviza la transición al horizonte y ajusta
ligeramente el cénit y los tonos cálidos a partir del color ambiental suministrado.

No clasifica píxeles azules del mundo, no añade un reloj inventado y no afirma
leer directamente la lluvia o la hora. No reemplaza estrellas, sol, luna ni
cielos de dimensiones mediante texturas nuevas.

La variación por canal se limita a `[-0.045,+0.015]` frente a la salida Vanilla
para cada entrada. Los casos sintéticos de día, ocaso, noche y ambiente gris
verifican ese límite y el alfa. No es una calibración artística sobre capturas.

## 5. Cloudcraft y protección del cielo

**Tratamiento cromático de caras implementado; formas redondas pendientes.**

Nuevo `core/clouds.fsh`, con la interfaz comprobada de `clouds.vsh` y su bloque
CloudInfo. Recupera la proporción de sombreado de cara respecto al color ambiental:
bases suavemente frías, superiores contenidas y tinte cálido según el ambiente.
Conserva geometría Vanilla, cobertura, alpha y fog de todas las fases OIT.
No genera nubes volumétricas ni redondea las siluetas.

Se retira del pipeline automático la extracción RGB de supuestas nubes, sus
cuatro pasadas de blur y el aporte aditivo CloudSoft/CloudWide al bloom. También
se retira el tratamiento de blancos como nubes de atmosphere_pass; su ajuste de
agua se conserva. Nieve y cuarzo dejan de recibir **ese tratamiento específico**.
El reconocimiento de emisores RGB todavía puede confundir superficies claras.

El grafo automático pasa de **26 a 21 pasadas** por esta separación semántica,
no por una campaña de optimización. Exposición, Toon Grade, acabado, contorno RGB
y ganancias del bloom de emisores se conservan.

**NV-SKY-001:** no se amplifica el bloom global y se elimina una fuente de halo
blanco del cielo. La preservación visual del cielo aprobado requiere A/B en juego;
no se declara cerrada basándose solo en estos cambios.

## 6. Chromaglow multifuente

**Fallback RGB ampliado / probado sintéticamente / sin clasificación por bloque.**

Se conserva el kernel de dos píxeles de la primera candidata y sus tintes.
Un segundo anillo de ocho muestras a radio 12 encuentra superficies más extensas
si hay contraste con un entorno oscuro y coherencia en el interior del material.
El aporte nuevo tiene un límite de peso 0.25 para color y 0.08 para neutros; no
se suben las ganancias globales de composición. Se mantiene el RGB de la fuente,
incluidos acentos violetas y verdes, sin convertir todo en luz blanca.

Mediciones contra el shader anterior: los núcleos cálido y frío de 3×3 producen
exactamente la misma salida (delta máximo 0). El centro de superficies 8×8,
anteriormente con salida cero, produce RGB cálido aproximadamente
`(0.2143,0.1714,0.0750)`, frío `(0.0702,0.1806,0.2006)` y neutro
`(0.0752,0.0752,0.0752)` con fondo 0.06.
[Datos de la comparación](V8_SYNTHETIC_EVIDENCE.json).

Se verificaron modelos Vanilla de antorchas (normal/almas/cobre), linternas,
glowstone, sea lantern, shroomlight, tres froglights, end rod, lámpara encendida,
respawn anchor cargado, hornos encendidos, vela, vines, lichen, lava, fuego,
campfires y beacon; también se consultaron sus blockstates. Esto prueba existencia
de recursos en el espejo, **no que el post-effect identifique esos bloques**.
La respuesta de cada fuente real, animación, distancia y exposición queda pendiente.

Un cuarzo iluminado en un fondo oscuro puede producir el mismo RGB que una lámpara.
No hay máscara de material, IDs, fullbright personalizado ni emisión coloreada
sobre bloques vecinos. NV-GLOW-001/002 tienen avances medibles, no cierre visual.

## 7. Inkline y Shape & Shade

El contorno automático por luminancia permanece sin cambios. El nuevo
`notvisuals:depth_ink` comparte el filtro de profundidad del laboratorio, oscurece
aristas con un tono neutro ligeramente frío, conserva alfa y protege altas luces.
Es **optativo**, separado del efecto automático, hasta confirmar los datos de
primera persona/transparencia. No activar junto con Depth Lab al comparar estilos.

No se implementaron SSAO, sombras proyectadas, normales de terreno ni iluminación
global. `terrain.vsh` de 26.3 no contiene el atributo Normal de las referencias.

## 8. Validación ejecutada

| Comprobación | Resultado de esta máquina |
| --- | --- |
| Validador del paquete | PASS: 5 efectos, 36 pasadas totales, 14 fragments propios referenciados |
| Unit tests y ejecución GLSL sintética | **21 tests PASS, 0 fallos, 0 omitidos**, con moderngl/numpy instalados |
| Grafos de efectos completos | Los 5 grafos renderizan una escena sintética; salidas finitas |
| Compilación genérica glslang 15.2.0 | **40 compilaciones PASS**: 16 entry points y 24 variantes OIT |
| OIT sintético | Compilación con 4/8/16 coeficientes y ambas convenciones de profundidad; comparación numérica de cobertura con 4 coeficientes |
| Cobertura de nubes | Alfa igual a Vanilla para distancias/colores/caras probados; depth bounds/transmittance sin variación numérica en los casos ensayados |
| Paquete ZIP | 24 archivos, raíz instalable, CRC e igualdad binaria de builds comprobadas |
| Minecraft 26.3 / ShaderC | **No ejecutado**; no hay cliente ni latest.log disponible |
| Capturas / vídeo real / OpenGL-Vulkan en juego | **No ejecutado**; llvmpipe EGL no demuestra ninguno de estos resultados |
| CI remoto | Ver estado real de GitHub Actions; las comprobaciones locales no establecen su resultado |

Los tests GPU son opcionales para la herramienta básica (solo stdlib). En CI
`NV_REQUIRE_GPU=1` hace fallar la ejecución si faltan dependencias/contratos;
no se convierte una ausencia de renderer en un éxito silencioso.

## 9. GitHub y build

- [PR #1](https://github.com/jonathanthxd/NotVisuals/pull/1).
- [Historial de la rama](https://github.com/jonathanthxd/NotVisuals/commits/feat/v8-ink-and-light).
- [Ejecuciones y artefactos](https://github.com/jonathanthxd/NotVisuals/actions).
- Build: `dist/NotVisuals_26.3_v8_candidate_2.zip`, **20598 bytes**, SHA-256
  `77d70e836fd23bf54d8be2a09b95bb6b4c932e5ac468046d6084f5c8d765ee88`.
- Primera candidata local preservada: SHA-256
  `a5fe37984fe51bcc5339345b2511ca269da1fac0f873570b2e126a1329bf0586`.

El workflow prepara el artefacto `NotVisuals-26.3-v8-candidate-2` tras pasar CI.
Su disponibilidad debe verificarse después del push. La API de GitHub devolvió
403 tanto por REST como por GraphQL durante la inspección; no se atribuye esto a
credenciales ausentes ni se solicitan tokens sin evidencia.

## 10. Testing manual

Copiar el ZIP nuevo sin extraer a `.minecraft/resourcepacks/`, activar únicamente
esta candidata y seguir [V8_TESTING_GUIDE.md](V8_TESTING_GUIDE.md). Registrar cliente,
API, resolución, FOV, escena, hora, clima y logs; comparar Vanilla/v7/v8.1/v8.2.
Depth Lab e Ink de profundidad se prueban por separado con sus comandos.

## 11. Limitaciones y riesgos

Los overrides core no son una API estable; otros packs/mods pueden reemplazarlos.
El espejo verifica interfaces, no la configuración de cada backend del cliente.
No hay exclusión fiable de mano/HUD ni materiales por píxel. La normalización de
device depth no equivale a distancia física. La nueva respuesta de superficies
grandes puede incluir falsos emisores; tiene pesos limitados, pero requiere QA.
Nubes Fancy conservan su forma de bloques y no reciben textura/volumen nuevos.
La candidata puede cambiar la percepción al retirar el antiguo halo de blancos:
comparar con la primera v8 antes de aprobarlo.

## 12. Próximas tareas y aceptación

1. Cargar la build en 26.3, revisar ShaderC y latest.log, verificar interfaces UBO.
2. Grabar el caso de mano con las dos candidatas para confirmar o descartar
   impulsos/clear values como causa de NV-DEPTH-001.
3. Ejecutar la matriz visual completa, especialmente cielo/nieve/cuarzo/agua y
   fuentes extensas; calibrar las ganancias con capturas comparables.
4. Verificar Fancy Clouds, lluvia y transparencias en las APIs realmente disponibles.
5. Solo después considerar contorno depth automático, formas de nube propias y
   señales de material más fiables. Mantener v8 experimental hasta aceptación.
