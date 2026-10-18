# Arquitectura — v8 candidata 2

La raíz del repositorio es la raíz del resource pack, formato `[97,1]`, destino
Minecraft Java 26.3. `main` conserva la referencia v7.

## Render paths e integración

- `assets/minecraft/shaders/core/sky.fsh`: override del fragment de cielo;
  consume las distancias emitidas por el vertex Vanilla y las UBO Fog y
  DynamicTransforms. Curva de horizonte y tinte acotado según color ambiental.
- `assets/minecraft/shaders/core/clouds.fsh`: override del fragment de nubes;
  consume distancia, vertexColor y la UBO CloudInfo ya utilizada por el vertex.
  Conserva alpha, fog, depth bounds, transmittance y acumulación OIT.
- No se reemplazan vertices core, terreno, modelos, texturas, estrellas, UI
  ni el pipeline de transparencia. No hay normales de terreno o IDs de material.
- `assets/minecraft/post_effect/end_of_frame.json`: efecto automático de **21
  pasadas**. Medición de exposición → adaptación persistente → grade → atmósfera
  de agua heredada → Inkline RGB → extracción de highlights → ocho pasadas de
  blur de bloom → composición → pixel adaptativo → fantasy → Toon Grade → acabado
  → blit. El historial de exposición es el único historial persistente.
- Las cinco pasadas de nubes por RGB de la primera candidata se retiran. Su
  máscara de blancos podía afectar nieve/cuarzo; Cloudcraft actúa en geometría
  de nubes y no aporta un halo blanco al bloom.

## Sistemas optativos

`pixel_vivid` y `soft_glow` son los modos heredados. `depth_lab` y `depth_ink`
leen depth de `minecraft:main` mediante `use_depth_buffer:true` y `bilinear:false`,
escriben un target intermedio propio y hacen blit al destino principal. Ninguno
está insertado automáticamente. No activarlos juntos en las comparaciones.

El include `notvisuals:depth_edges.glsl` compara texels exactos, rechaza depth
no válido y exige continuidad tangencial. Su escala de device depth es simétrica
bajo inversión Z; no reconstruye profundidad lineal, normales ni SSAO. El
filtrado suprime impulsos pero puede perder detalles pequeños y bordes contra clear.

## Contratos y validación

`docs/V8_RENDERER_CONTRACT.json` fija rutas, hashes y SHA del espejo de assets
26.3. `scripts/shader_sources.py --fetch /tmp/notvisuals-26.3` descarga y verifica
los contratos **fuera del pack**, sin desactivar TLS o checksums. Los includes
Vanilla no se copian a los assets del proyecto. Los core fragments se escriben
para sus interfaces; no proceden de los ZIP adjuntos.

`validate_pack.py` comprueba grafo, orden, read-before-write, conflictos de
lectura/escritura, samplers en ambas direcciones, depth no filtrado, includes,
entry points core y fragments huérfanos. `check_glsl.py` expande includes y
compila entradas/variantes con glslang. `test_gpu.py` ejecuta shaders y los cinco
grafos sobre buffers sintéticos EGL/Mesa, sin iniciar Minecraft.

## Límites

Chromaglow reconoce apariencia RGB y contraste, no bloques. Un blanco iluminado
puede parecer una lámpara. El postprocess no identifica mano, HUD ni capas de
transparencia de forma fiable. No hay sombras geométricas, volumetría, GI ni
propagación de luz coloreada. Los overrides core requieren validación con el
ShaderC del cliente y pueden entrar en conflicto con otros packs/renderers.

Consultar el [informe](V8_IMPLEMENTATION_REPORT.md), la
[investigación](V8_REFERENCE_RESEARCH.md) y la [guía de QA](V8_TESTING_GUIDE.md).
