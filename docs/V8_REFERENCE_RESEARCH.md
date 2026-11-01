# Investigación de referencias — candidata v8.2

## Alcance y procedencia

Base: `33fafc579658d20ece13066e4f546b533e5f5a08`, rama
`feat/v8-ink-and-light`, PR #1. Se leyó el comentario de QA del propietario
del 18 de octubre de 2026 desde la página pública del PR; la API devolvió 403.
Los adjuntos se abrieron fuera del checkout, sin ejecutar su contenido.

Inventario comprobado: **269 archivos**. `Experimental So Tuff.zip`: 124 JSON,
45 PNG y 20 metadatos de animación (189). `Fog.zip`: 5 includes GLSL, un
vertex y un fragment (7). `shaders experimental.zip`: 20 JSON, 25 fragment,
24 vertex y 4 includes (73). Todos los JSON se parsearon y todas las imágenes
se decodificaron; se analizaron estructura, interfaces y grupos funcionales.
El anexo [V8_REFERENCE_INVENTORY.csv](V8_REFERENCE_INVENTORY.csv) registra cada
entrada, tamaño y SHA-256, sin redistribuir sus implementaciones ni texturas.

No hay LICENSE, autor o permiso de redistribución identificable en los tres
ZIP. «Made with Blockbench», `format_version: 1.21.11` y enlaces a herramientas
no conceden licencia. **No se incorpora literalmente ningún recurso adjunto.**
Las soluciones nuevas se escriben para los contratos actuales del renderer.

## Matriz de técnicas y decisiones (antes de implementación)

| Grupo de archivos | Técnica / problema | Origen, dependencias e interfaces | Aplicabilidad y riesgos en 26.3 | Licencia | Alternativa original / destino |
| --- | --- | --- | --- | --- | --- |
| So Tuff: `template_torch*`, `template_*lantern*`, modelos item | Capas de geometría y planos luminosos para destacar un emisor | Modelos Blockbench 1.21.11; `elements`, UV, padres, `shade:false` | No son emisión de luz; planos grandes pueden producir halos cuadrados, solapamientos y costes de transparencia; no sustituir plantillas globales | No identificada | Conservar geometría Vanilla; extracción multiescala por contraste, Chromaglow |
| So Tuff: familias candle y cake (plantillas + variantes de colores) | Varias capas por llama; 8–32 elementos según número de velas | JSON de modelos y texturas auxiliares; 5 elementos sin sombrear por vela | Cambia geometría y legibilidad; el color de la vela no identifica su llama | No identificada | No importar modelos; probar llamas pequeñas y animaciones como señales RGB, sin prometer clasificación |
| So Tuff: `cave_vines*`, `glow_lichen*`, `end_rod`, `respawn_anchor_[1-4]`, `blast_furnace_on`, portal | Detalles emisores sobre superficies específicas | Padres Vanilla, cruces y superficies superpuestas; algunos modelos desactivan AO | `shade:false` elimina sombreado direccional, no asegura fullbright ni luz hacia vecinos; estados/UV deben verificarse | No identificada | Inventario de recursos de 26.3, sin reemplazar bloques; casos de prueba de Chromaglow |
| So Tuff: 45 PNG, `*_glow.png`, `white.png`, 20 `.mcmeta` | Brillo animado e interpolado; sprites de núcleo/halo | Atlas de texturas y `animation.frametime`, `interpolate` | Dependencia del material/atlas; `blast_furnace_glosw.png` es un nombre sospechoso, no una API | No identificada | Ninguna textura copiada; mantener el color de la señal y evitar modulación temporal propia |
| Fog: `minecraft/shaders/include/fog.glsl` | Inicio/final escalados y curva de densidad | GLSL 150, `FogStart`, `FogEnd`, `FogShape`, matriz ModelView | Contrato antiguo; `smoothstep(end,start,x)` con extremos invertidos no tiene resultado garantizado en GLSL | No identificada | Curva monotónica con extremos ordenados sobre la distancia de cielo/nubes, sin tocar fog global |
| Fog: includes y `sodium/shaders/blocks/*` | Fog esférico/cilíndrico, matrices de chunk | Sodium + shader-support 1.19.3/1.19.4; atributos compactados | No Vanilla, no port directo; no añadir dependencia de Sodium | No identificada | Descartar integración; conservar ideas matemáticas y las UBO actuales de 26.3 |
| Experimental: `program/depth.*`, `post/transparency.json` | Elegir la profundidad visible de varias capas y codificarla en RGB | Samplers Diffuse/Translucent/ItemEntity/Particles/Weather/Clouds; `auxtargets`, `intarget` | Targets antiguos, near=0.05/far=256 no justificados; mezcla presupone profundidad convencional | No identificada | No portar ni linealizar con constantes inventadas; point sampling, validez del vecindario y coherencia de saltos, Depth Stability |
| Experimental: `program/highlights.*` | Selección por diferencia de profundidad y color, soporte de varias muestras | Profundidad RGB codificada y kernel de radio variable | No equivale a SSAO; su contrato no existe en el efecto final actual | No identificada | Vecindario coherente de profundidad sin historial ni datos inventados; laboratorio e Inkline optativo |
| Experimental: `program/glow.*`, `program/color.*` | Extraer y dispersar altas luces, composición cromática | GLSL 150, DiffuseSampler, OutSize, ColorModulate; kernel grande | Umbral global induce bloom en cielo/nieve; bucle costoso y neutralización del color | No identificada | Contraste local a dos escalas, conservación del RGB y ganancias limitadas; Chromaglow |
| Experimental: `include/light.glsl`, terreno `core/rendertype_{solid,cutout*,translucent*,tripwire}.*` | Luz por normales/lightmap y aparente emisión | Atributo `Normal`, UV2 y uniforms antiguos; control por alfa de textura | 26.3 `terrain.vsh` no proporciona Normal; alfa codificada afecta cutout/transparencias | No identificada | No reemplazar terreno ni codificar materiales en alfa; conservar Shape & Shade aparente |
| Experimental: `include/player.glsl`, shaders de entidades/armadura/sombra | Colores de control en textura, luz y overlay de daño | Muestreo de posiciones fijas en skins; uniform/atributos antiguos | Colores de control no son IDs de material; interferencia con skins, mano y overlays | No identificada | No importar; no afirmar exclusión semántica de primera persona desde depth |
| Experimental: partículas, beacon, text, leash, position y variantes core | Composición de capas, UI y transparencias | GLSL 150, nombres antiguos, screen-door en beacon | Reemplazo amplio rompe render paths y texto; no hace falta para el objetivo | No identificada | Mantener estos render paths Vanilla y probarlos como regresión |
| Experimental: `include/noise.glsl` | Ruido procedural 4D | Funciones GLSL autónomas, procedencia no acreditada | No aporta separación semántica ni estabilidad temporal por sí solo | No identificada | No copiar ni introducir ruido animado para disimular artefactos |
| Experimental: `program/data.*`, `dof.*`, `dofblur.*` | Historial de exposición/foco, profundidad y blur | Targets RGB de datos, sondeo de centro, feedback persistente | Foco constante perjudica nitidez; historial no corrige depth incorrecta | No identificada | Mantener exposición existente; DOF e historial de depth descartados en esta iteración |

## Interfaces actuales verificadas

Se consultó el espejo de assets `InventivetalentDev/minecraft-assets`, rama
`26.3`, SHA `f44cf36a295b1ecb0d34516765a44a8b5be10761`. Es un espejo de
assets, no una garantía de API estable ni una prueba dentro del juego.
Las descargas de Mojang se rechazaron por la política de red (403).

- `core/sky.fsh`: entradas de distancia esférica/cilíndrica, UBO Fog y
  DynamicTransforms; no da hora/clima explícitos. El color ambiental sirve
  de señal continua, sin inventar un reloj ni detectar píxeles azules del mundo.
- `core/clouds.fsh`: distancia y vertexColor; variantes OIT_DEPTH_BOUNDS,
  OIT_TRANSMITTANCE, OIT_ACCUMULATE y OIT_ALPHA_ONLY. La cobertura y el fog
  deben ser idénticos entre fases. El sombreado de caras ya viene del vertex.
- `core/clouds.vsh`: CloudFaces, CloudInfo, colores por cara, gl_VertexIndex.
  No se reemplaza su geometría. La candidata no promete siluetas redondas
  ni nubes volumétricas.
- `core/terrain.vsh`: Position, Color, UV0, UV2; sin Normal. No insertar
  sombras geométricas inventadas ni modificar el pipeline de transparencias.
- Depth Lab recibe solo `minecraft:main` depth con filtrado desactivado;
  carece de proyección inversa, IDs de mano y profundidad de todas las capas.

Las decisiones y resultados de implementación se registran en
[V8_IMPLEMENTATION_REPORT.md](V8_IMPLEMENTATION_REPORT.md). La matriz separa
conceptos investigados de capacidades efectivamente comprobadas.
