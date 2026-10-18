# Guía de pruebas — NotVisuals v8 candidata 2

Esta build es **experimental**. Las verificaciones automatizadas descritas en el
[informe](V8_IMPLEMENTATION_REPORT.md) se ejecutaron; las escenas Minecraft de
esta guía **siguen pendientes**. No confundir buffers sintéticos con gameplay.

## 1. Construcción y pruebas automatizadas

Python 3.10+ y stdlib bastan para construir el pack:

```bash
cd /workspace/NotVisuals
python3 scripts/validate_pack.py
python3 -m unittest discover -s scripts -p 'test_pack.py' -v
python3 scripts/build_pack.py
python3 -m zipfile -t dist/NotVisuals_26.3_v8_candidate_2.zip
```

Los tests de ejecución GLSL usan herramientas de desarrollo opcionales. En esta
máquina se preparó `/tmp/notvisuals-tools`; para reproducirlos con Python 3.12:

```bash
python3 -m venv /tmp/notvisuals-tools
/tmp/notvisuals-tools/bin/pip install -r scripts/requirements-gpu.txt
python3 scripts/shader_sources.py --fetch /tmp/notvisuals-26.3
NV_REQUIRE_GPU=1 NV_VANILLA_ROOT=/tmp/notvisuals-26.3 \
  MESA_SHADER_CACHE_DIR=/tmp/notvisuals-mesa \
  /tmp/notvisuals-tools/bin/python -m unittest discover -s scripts -p 'test_*.py' -v
python3 scripts/check_glsl.py --vanilla-root /tmp/notvisuals-26.3
```

Se requiere EGL/Mesa para estos tests y glslangValidator para el último comando.
En esta máquina el compilador está en
`/tmp/notvisuals-glslang/usr/bin/glslangValidator` (pasar `--compiler` con esa ruta).
El workflow instala glslang-tools y las bibliotecas Mesa. Los pins GPU requieren
Python 3.11+; no cambian la dependencia básica del pack. Las descargas se verifican
contra el manifiesto fijado; nunca desactivar TLS/checksums para hacerlas pasar.

Resultado esperado actual: **21 tests, sin fallos ni omitidos**, y 40 compilaciones
GLSL. Sin las dependencias GPU, unittest puede omitir su clase: ese resultado no
valida ejecución GLSL. `NV_REQUIRE_GPU=1` lo convierte en error, como en CI.

Los grafos de los cinco efectos se ejecutan sobre una escena sintética. También
se verifican impulsos y jitter de depth, aristas continuas y Z invertida, alfa de
nubes, variantes OIT y límites de cielo. No valida ShaderC, drivers del propietario,
visibilidad real de la mano, aceptación artística ni FPS.

## 2. Instalar sin sobrescribir la primera candidata

1. Conserva `NotVisuals_26.3_v8_candidate.zip` para comparación.
2. Copia **sin extraer** `NotVisuals_26.3_v8_candidate_2.zip` a
   `.minecraft/resourcepacks/`. El ZIP tiene pack.mcmeta, pack.png y assets en raíz.
3. Activa solamente la candidata que vas a evaluar en Minecraft Java **26.3
   Vanilla**. No superpongas v7/v8 ni otros packs que modifiquen shaders.
4. El efecto base y los fragments core de cielo/nubes son automáticos. Empieza
   con todos los efectos opcionales desactivados.
5. Revisa latest.log tras cargar y tras F3+T. Busca ShaderC, notvisuals, sky,
   clouds, uniform, sampler, Framebuffer, error y Failed; conserva el contexto.
6. Si falla la carga o aparece pantalla negra, retira la candidata, guarda el log
   y conserva el primer ZIP. No des por correcto un pack que no cargó sus shaders.

El artefacto CI previsto se llama `NotVisuals-26.3-v8-candidate-2` en
[GitHub Actions](https://github.com/jonathanthxd/NotVisuals/actions). Comprobar que
la ejecución correspondiente terminó antes de asumir que está disponible.

## 3. Depth Lab y contorno oscuro — probar por separado

```mcfunction
/posteffect add @s notvisuals:depth_lab
/posteffect list @s
/posteffect remove @s notvisuals:depth_lab
/posteffect add @s notvisuals:depth_ink
/posteffect remove @s notvisuals:depth_ink
```

Cian es diagnóstico. `depth_ink` es una variante oscura opcional; no forma parte
del pipeline automático. No activar ambos a la vez. `/posteffect clear @s` quita
los efectos añadidos por comandos, pero no desactiva el efecto automático del pack.

Para NV-DEPTH-001/002, grabar vídeo con cámara fija y con movimiento rápido:

- Mano vacía, antorcha, espada y herramienta en primera persona.
- Ataque, uso de objetos y cambio de objetos; repetir con mano/HUD ocultos (F1)
  y tercera persona para separar sus contribuciones.
- Entidades móviles, vallas, hierba, hojas, cristales, agua y partículas.
- Aristas contra otras superficies y contra cielo, esquinas, objetos lejanos y
  bordes de pantalla. El filtro puede omitir detalles de menos de tres píxeles
  y límites contra clear; registrar pérdidas de contornos además de ruido.
- Distintas resoluciones/escalas de renderizado. Repetir en las APIs realmente
  disponibles, sin presentar una API no probada como compatible.

El nuevo filtro corrige casos sintéticos; **no confirma la causa del flicker de
la mano real**. No cerrar el defecto sin vídeo/log de la escena reproducida.

## 4. Matriz visual obligatoria

En todas las filas comparar **A Vanilla, B v7, C primera v8, D candidata 2** con
la misma cámara, FOV, brillo, resolución, nubes, render distance, semilla,
coordenadas, hora y clima. No activar las cuatro a la vez. Registrar build
exacta del cliente, API, GPU/driver y fecha; capturas emparejadas y vídeo si parpadea.

| Escena | Revisión y criterio |
| --- | --- |
| Día despejado | NV-SKY-001/002: cielo legible, sin aumento de halo; colores agradables |
| Cielo con nubes y Fancy Clouds | NV-CLOUD-001: bases y superiores diferenciadas, cobertura/transparencia sin huecos |
| Amanecer | Transición continua, horizonte cálido sin blanco quemado |
| Atardecer y sol entre nubes | Separación cielo/nube/sol; comprobar que no vuelve el bloom descontrolado |
| Noche | Estrellas y luna legibles; sin cambios no previstos en sus render paths |
| Lluvia y tormenta | Color ambiental continuo; fog y fases OIT coherentes |
| Bosque | Texturas de hojas/hierba y falsos contornos |
| Montañas | Siluetas legibles, distancia y niebla sin ocultar construcciones |
| Nieve y construcción de cuarzo/blancos | NV-GLOW-002: no tratar blancos como nubes; buscar falsos emisores RGB |
| Costa y agua bajo cielo azul | No aplicar tintes core de cielo a agua; revisar transparencias |
| Cueva con antorchas | Halo de referencia preservado; sin aumentar núcleo/alcance excesivamente |
| Cueva con almas | Halo frío y color original; sin tinte azul general |
| Sala con glowstone | Respuesta de superficies extensas y texturas legibles |
| Sala con sea lantern | Halo neutro/frío contenido; comparar con blanco no emisor |
| Construcción con lámparas | Encendidas/apagadas y distancia; falsos positivos |
| Respawn anchor | Estados 0–4, núcleo y acento cromático; no halo permanente al apagar |
| Nether | Lava, fuego, almas, interiores, color de dimensión |
| End | Mantener identidad de dimensión; end rods y transparencias |
| Mano vacía y con objetos | NV-DEPTH-001: vídeo ataque/uso/cambio, fixed y moving camera |
| Entidades en movimiento | Estabilidad de bordes, sombras y partículas |
| Inventario, chat, HUD y F1 | Alfa, textos, overlays y falsos bordes |

Fijar condiciones donde proceda con `/time set noon`, `/time set midnight`,
`/weather clear` y `/weather rain`. Registrar también transición natural de hora
para detectar saltos que una escena fija oculta.

## 5. Inventario de emisores a probar

Estos recursos existen en los modelos consultados de 26.3. **No están clasificados
por nombre en el shader**: la selección se hace por RGB y contraste, y su respuesta
en juego permanece sin validar. No garantizar cobertura de toda una familia.

| Fuentes | Estados / prueba |
| --- | --- |
| Torch, Soul Torch, Copper Torch | Suelo/pared, mano y animación; referencia de núcleo pequeño |
| Lantern, Soul Lantern, Copper Lantern | Suelo/colgante, interior y exterior; variaciones de cobre |
| Glowstone, Sea Lantern, Shroomlight | Caras grandes y pequeñas en perspectiva, fondo claro/oscuro |
| Ochre / Verdant / Pearlescent Froglight | Color propio preservado y orientaciones |
| End Rod | Orientaciones, tamaño lejano y partículas |
| Redstone Lamp | Lit=false frente a lit=true |
| Respawn Anchor | Charges 0–4 y distintas caras |
| Blast Furnace, Furnace, Smoker | Lit=false/true, frontal frente a laterales |
| Candles y candles on cake | Apagadas/encendidas, 1–4 velas y colores |
| Cave Vines / glow berries, Glow Lichen | Estado con/sin berries, orientación y tamaño lejano |
| Lava, Fire, Soul Fire | Animación, reflejos aparentes y límites de superficies extensas |
| Campfire / Soul Campfire | Encendido/apagado, humo y transparencias |
| Beacon | Bloque, haz y transparencias |

Repetir con nieve, cuarzo, lana blanca, bloques azules/amarillos y cristal bajo
iluminación semejante. Comparar geometría luminosa real con falsos emisores.
El fallback RGB no puede distinguir materiales que terminan con el mismo color.

## 6. Informe de prueba y puertas de aceptación

Registrar escena, pasos, esperado/observado, ZIP/hash, configuración, vídeos y
extractos de latest.log sin datos personales. Separar efectos base, depth_lab,
depth_ink y otros opcionales. Para cada NV-* marcar pendiente/pasa/falla según
evidencia real; no deducir aceptación artística de un test estático.

Puertas: automatización → carga ShaderC y renderer → QA visual comparativa →
aprobación del propietario. Mantener experimental hasta superarlas. No hacer
merge, release ni publicación en Modrinth desde estas pruebas.
