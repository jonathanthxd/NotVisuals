# Arquitectura de renderizado — NotVisuals v8 candidata

## Alcance y estabilidad

Objetivo: Minecraft Java 26.3, resource pack Vanilla sin mods obligatorios. La rama `main` sigue en v7. Las nuevas funciones descritas aquí están **implementadas en archivos fuente** y pasan comprobaciones estáticas; **no se ha probado todavía ShaderC ni el runtime del cliente**. Este documento no constituye aprobación visual.

## Punto de entrada y flujo

- Metadatos: `pack.mcmeta` (`min_format`/`max_format` `[97, 1]`) y `pack.png`.
- Pipeline automático: `assets/minecraft/post_effect/end_of_frame.json`, 26 pasadas.
- Efectos optativos: `notvisuals:pixel_vivid`, `notvisuals:soft_glow`, `notvisuals:depth_lab`.
- GLSL: `assets/notvisuals/shaders/post/*.fsh`. Los fragment shaders propios reciben samplers nombrados `<InputName>Sampler`.
- El motor provee `minecraft:core/screenquad` y los shaders de blur/blit. No hay sobremontajes de `assets/minecraft/shaders/core` en esta etapa.

### Pipeline automático (orden efectivo)

1. `minecraft:main` → medida de luminancia a 1×1 (`nv_luma_now`).
2. Adaptación usando `nv_exposure_history`, target 1×1 **persistente**, y copia de historia.
3. `vivid_grade` → `nv_scene`.
4. `atmosphere_pass` → `nv_atmosphere` (heurísticas de agua/nubes heredadas).
5. `inkline` → `nv_inked`: refuerzo oscuro local en bordes de contraste.
6. `highlight_extract` → `nv_highlights`: Chromaglow, selección conservadora.
7. `cloud_extract` → `nv_clouds`: **heurística heredada sin identidad geométrica**.
8. Ocho pasadas de blur para cuatro escalas de highlights; cuatro pasadas de blur para dos escalas de nubes.
9. `bloom_composite` → `nv_bloomed`: combina escena, highlights y la aproximación de nubes.
10. `adaptive_pixel` → `nv_pixel`.
11. `fantasy_pass` → `nv_fantasy`.
12. `toon_grade` → `nv_toon`: posterización suave únicamente en medios tonos.
13. `vivid_finish` → `nv_final`.
14. `minecraft:post/blit` → `minecraft:main`.

La versión legible máquina del grafo JSON es autoritativa ante cambios posteriores. Los targets intermedios excepto historia carecen de persistencia explícita.

## Sistemas y señales realmente disponibles

| Sistema | Origen de información | Resultado real | Limitación |
| --- | --- | --- | --- |
| Inkline | Color/luminancia final, vecinos | Contorno y sombreado *aparentes* | Sin depth ni ID de bloque, afecta posible HUD |
| Chromaglow | Brillo y contraste local, tonalidad | Halo cálido/frío aproximado | No identifica antorchas ni materiales |
| Toon Grade | Luminancia de salida | Cuantización leve de medios tonos | No distingue biomas ni dimensiones |
| Exposure | Media logarítmica de muestras 5×5 + historia 1×1 | Adaptación temporal | Heurística global, influye el contenido de pantalla |
| Bloom | Cuatro desenfoques de highlights | Resplandor multinivel | Puede iluminar píxeles no emisores |
| Cloud extract v7 | Blancos de luminancia alta | Glow de máscara heurística | Falsos positivos: nieve, arena, piedra |
| Depth Lab | `minecraft:main`, `use_depth_buffer: true` | Diagnóstico cian **cuando se active** | OIT/API/profundidad no validados |
| Cloudcraft y Skyflow reales | Requieren acceso correcto a shaders específicos | No implementados | Core shader overrides inestables |

### Depth Lab

`assets/notvisuals/post_effect/depth_lab.json` no participa del efecto automático. Solo se activa con `/posteffect add @s notvisuals:depth_lab`. Usa `use_depth_buffer: true` sobre `minecraft:main`, sin matrices de cámara ni linealización; compara valores no lineales de vecinos. Puede fallar o revelar datos inutilizables. **No constituye SSAO ni contorno geométrico terminado.**

### Versiones de renderer y cuidado con ShaderC

Minecraft 26.3 utiliza ShaderC en OpenGL y Vulkan, salidas de shader vinculadas por `layout(location=...)` y OIT. El renderer renombró `core/rendertype_clouds.*` a `core/clouds.*`. Sobrescribir core shaders está expresamente considerado por Mojang **no soportado** como API estable de resource packs.

Fuentes de ingeniería:
- [Minecraft Java Edition 26.3 — Mojang](https://www.minecraft.net/en-us/article/minecraft-java-edition-26-3)
- [Código de referencia de shaders 26.3 — MC Assets](https://mcasset.cloud/26.3/assets/minecraft/shaders/core)

Se decidió **no añadir todavía** `core/clouds.fsh`, `core/sky.fsh` ni overrides de terreno: la implementación requiere comparar fuentes exactas de la build final y validación de compilación, OIT y ambos backends en cliente real. Hacerlo a partir de shaders antiguos podría provocar fallos de renderizado.

## Validación y construcción

`scripts/validate_pack.py` comprueba formato, entradas, rutas, dependencias entre buffers, riesgo de lectura y escritura simultáneas, samplers definidos y sintaxis estructural básica. `scripts/test_pack.py` incluye pruebas negativas y ZIP determinista. CI usa `glslangValidator` como comprobación sintáctica GLSL adicional: **no reproduce ShaderC ni es una prueba en Minecraft**.

`scripts/build_pack.py` produce `dist/NotVisuals_26.3_v8_candidate.zip` sin incluir herramientas internas.

## Errores y riesgos por validar

- Color-edge no equivale a sombreado direccional real y puede afectar bordes de UI.
- Si hay parpadeo, los umbrales Inkline y cromáticos deben revisarse mediante capturas con movimiento.
- Bloom y nubes heredadas pueden afectar superficies claras no emisoras.
- El target `main` de profundidad podría estar vacío, resuelto de forma diferente o comportarse distinto bajo OIT.
- No se ha medido ni prometido FPS.
