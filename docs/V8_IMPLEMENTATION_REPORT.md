# NotVisuals v8 — Informe de implementación (candidato experimental)

**Proyecto:** NotVisuals, Minecraft Java 26.3, resource pack Vanilla.  
**Rama:** `feat/v8-ink-and-light`  
**Base estable:** v7 en `main` (intacta)  
**Estado de entrega:** implementación parcial comprobable por CI, **sin prueba runtime en Minecraft**.

## Resumen ejecutivo

Se implementaron tres cambios gráficos diferenciados respecto a la referencia v7: `Inkline` (contrastes y cavidades aparentes), `Chromaglow` (selección más cuidadosa de luces visibles con sesgos de color) y `Toon Grade` (medios tonos ligeramente cuantizados). Se añadió un `Depth Lab` optativo que permite ensayar el sampler de profundidad sin convertirlo en dependencia del efecto automático.

El cambio de 24 a **26 pasadas** corresponde a Inkline y Toon Grade; el laboratorio de profundidad es una definición aparte, no una pasada automática. Se ampliaron scripts, tests y el flujo CI para que la distribución experimental no se confunda con una versión estable.

**Valoración de alcance:** avances funcionales de base en 3 sistemas visuales + laboratorio, pero no hay aceptación de ningún sistema por QA visual. No es razonable afirmar una cobertura porcentual precisa ni presentar la candidata como completa.

## Características y evidencia

| Sistema | Código entregado | Verificación conseguida | Sin demostrar |
| --- | --- | --- | --- |
| Shape & Shade | Tono aparente en `inkline.fsh` | Referencias y GLSL estáticos | Normales de caras, sombras geométricas, SSAO |
| Inkline | `inkline.fsh` + paso automático | Grafo JSON y sintaxis estática | Siluetas reales por profundidad, HUD, flicker |
| Chromaglow | `highlight_extract.fsh` reformulado | Sintaxis y flujo existentes | Identidad de materiales, color real de luz, QA |
| Cloudcraft | Código v7 conservado | Sin cambios nuevos significativos | Nubes fluffy por geometría y OIT |
| Skyflow | Código v7 conservado | Sin cambios nuevos significativos | Gradientes por geometría y clima |
| Toon Grade | `toon_grade.fsh` + paso automático | Grafo y sintaxis estática | Calibración con screenshots |
| Depth Lab | `depth_lab.json`, `depth_lab.fsh` | Contrato JSON estático | Que `minecraft:main` depth sea útil en runtime |

### Cambios por módulo

- `assets/minecraft/post_effect/end_of_frame.json`: `nv_inked` tras atmósfera, `nv_toon` antes de `vivid_finish`; las etapas siguientes consumen los targets correctos.
- `assets/notvisuals/shaders/post/inkline.fsh`: muestreo de cuatro vecinos, umbrales para bordes en lado oscuro y tonos azul-neutros.
- `assets/notvisuals/shaders/post/highlight_extract.fsh`: elimina la extracción amplia y favorece máximos locales para mitigar halos en blancos uniformes.
- `assets/notvisuals/shaders/post/toon_grade.fsh`: dither ordenado de 2×2, 15 niveles de luminosidad y mezcla suave solo en medios tonos.
- `assets/notvisuals/post_effect/depth_lab.json` + `depth_lab.fsh`: visualización cian opcional de saltos de profundidad, **no SSAO**.
- Scripts y workflow: controles de dependencia y sampler, test de errores inyectados, determinismo ZIP, verificación estática con glslang y artefacto CI.

## Pruebas

Comprobadas por la automatización: estructura del pack, JSON, targets, dependencias del grafo, existencia de shaders, uniform sampler del fragment shader, balance estructural GLSL, validación GLSL genérica, generación/repetibilidad del ZIP. Consultar las ejecuciones de [GitHub Actions](https://github.com/jonathanthxd/NotVisuals/actions).

**No realizadas:** arranque del cliente 26.3, ShaderC runtime, capturas reales, comparación con v7, estrés de OIT/OpenGL/Vulkan, pruebas de todos los biomas/dimensiones, mediciones de FPS.

## Riesgos técnicos y descartes justificados

1. **Profundidad:** no se conoce todavía su representación efectiva bajo la etapa final con OIT. Se relegó a diagnóstico optativo.
2. **Sombras de caras:** el postprocesamiento de color carece de normales completas; una implementación geométrica requiere explorar terrain shaders actuales y test de visualización.
3. **Luces:** no hay identificadores de bloques/emisores por píxel final; se implementa aproximación conservadora, sin prometer propagación de luz coloreada.
4. **Nubes:** la detección RGB de v7 puede afectar nieve y superficies pálidas. El salto a core clouds requiere confirmar interfaces y probar OIT, no se vende como resuelto.
5. **Cielo:** no se añadió un shader core de cielo sin validación de shader inputs, dimensiones y clima.
6. **HUD:** la etapa final de postprocesamiento no aporta máscara de UI garantizada.
7. **Rendimiento:** no cuantificado; se prioriza visual.

## Próximas tareas abiertas

- Ejecutar matriz real [V8_TESTING_GUIDE.md](V8_TESTING_GUIDE.md).
- Confirmar sampler de profundidad. Si es utilizable, desarrollar contornos/depth-contact con control de transparencias.
- Investigar y probar intervención de shaders de terreno/nubes/cielo de la build estable 26.3 en una rama o experimento aislado.
- Calibrar resultados mediante imágenes comparables y resolver defectos antes de fusionar.
- Generar y aprobar la Gold Master. No hacer merge ni release ni Modrinth sin autorización.

## Fuentes técnicas

- [Mojang — Minecraft 26.3](https://www.minecraft.net/en-us/article/minecraft-java-edition-26-3)
- [Shaders de 26.3 — MC Assets](https://mcasset.cloud/26.3/assets/minecraft/shaders/core)
- [Dirección visual NotVisuals](VISUAL_DIRECTION_V8.md)
