# Guía de pruebas NotVisuals v8 — Ink & Light

**Objetivo:** comprobar una **candidata experimental**, no una release. Se necesita Minecraft Java **26.3** sin mods obligatorios. **No** se han ejecutado estas pruebas todavía; el documento indica exactamente cómo realizarlas.

## 1. Construir, instalar y activar

1. Obtén el ZIP de la compilación `NotVisuals-26.3-v8-candidate` desde el artefacto del último workflow correcto en [GitHub Actions](https://github.com/jonathanthxd/NotVisuals/actions), o ejecuta `python3 scripts/validate_pack.py`, `python3 -m unittest discover -s scripts -p "test_*.py" -v` y `python3 scripts/build_pack.py` desde esta rama.
2. Comprueba que el ZIP contiene en su raíz `pack.mcmeta`, `pack.png` y `assets/` (no una carpeta extra).
3. Copia `NotVisuals_26.3_v8_candidate.zip` sin extraer en `.minecraft/resourcepacks/`.
4. Abre Minecraft Java 26.3 **Vanilla**. Selecciona el pack experimental desde Opciones → Paquetes de recursos.
5. Entra a un mundo de pruebas. Si el renderizador falla, retira el pack desde el menú o desde la carpeta y conserva `latest.log`.
6. Comprueba en `.minecraft/logs/latest.log` mensajes relevantes a `ShaderC`, `notvisuals`, `Failed`, `shader`, `post_effect`, `Framebuffer` o `error`. Guarda las líneas completas con contexto.

**Configuración consistente:** igual resolución, distancia de renderizado, brillo, tipo de nubes, API (OpenGL o Vulkan), FOV y cámara para Vanilla / v7 / v8. Desactiva otros resource packs que modifiquen shaders. El efecto automático se habilita al activar el pack: no necesita `/posteffect add`.

## 2. Laboratorio de profundidad (opcional, experimental)

En un mundo con permisos para comandos:

```mcfunction
/posteffect add @s notvisuals:depth_lab
/posteffect list @s
/posteffect remove @s notvisuals:depth_lab
```

Se buscan **marcas cian en discontinuidades de profundidad**, no sombras reales. Comprueba paredes contra cielo, vallas contra bosque, hojas, vidrio, agua, entidad moviéndose y HUD. Si no aparece nada, todo sale cian o cambia con la API/transparencias, documenta logs y capturas; **no asumas que la profundidad funciona**. Quita el efecto antes de comparar la apariencia v8 base.

## 3. Matriz mínima de escenas reproducibles

| Escena | Qué comparar |
| --- | --- |
| Aldea de día | Inkline, volumen aparente, brillo |
| Estructura de piedra | Aristas, orientación visual, halos |
| Bosque denso | Falsos contornos de hojas y hierba |
| Cueva oscura | Negros, lectura de detalle, exposición |
| Cueva con antorchas | Halo cálido, falsos positivos |
| Cueva con antorchas de almas | Halo frío, neutralidad de azules |
| Nieve / cuarzo / piedra blanca | Ausencia de glow en blancos no emisores |
| Costa y agua | Azul del cielo frente a agua / transparencia |
| Amanecer | Degradado y bloom del horizonte |
| Atardecer | Tintes, nubes, apariencia original |
| Noche despejada | Luna, estrellas, contraste y banding |
| Tormenta | Oscuridad, interferencia de nubes y niebla |
| Nether | Lava, fuego y tonos intensos |
| End | Paleta y cielo diferenciados |
| Entidades en movimiento | Estabilidad y ruido de contornos |
| Inventario / chat / HUD | Textos, iconos y bordes falsos |

Para repetir una captura, anota coordenadas con F3, dirección de cámara, FOV y condiciones. Puedes fijar la hora y clima con `/time set noon` y `/weather clear`, o `/time set midnight` para noche. No cambies brillo entre pruebas. Captura tanto imágenes favorables como escenas donde aparezcan errores.

## 4. Comparación A/B/C

Haz tres capturas por escena: **A Vanilla (sin pack), B NotVisuals v7, C v8 candidata**. No actives v7 y v8 a la vez. Mantén misma vista y ajustes, registra cliente, GPU, API, resolución y fecha. Evalúa subjetivamente en escala 0–5: profundidad, contornos, luz, cielo/nubes, legibilidad, errores, constancia de color y estabilidad al mover la cámara.

## 5. Procedimiento para reportar un bug

Abre [GitHub Issues](https://github.com/jonathanthxd/NotVisuals/issues) con:

- Título claro y versión exacta.
- API gráfica, GPU/driver, resolución, gráficos y distancia de renderizado.
- Pasos exactos, escena/semilla/coordenadas/hora y tipo de nubes.
- Comportamiento esperado frente al observado.
- Capturas comparativas (Vanilla, v7, v8); vídeo si hay flicker.
- Extracto contextual de `latest.log` sin datos privados.
- Indica si el error solo aparece con `depth_lab` activado.

No informar «pasó en Minecraft» ni «FPS iguales» sin reproducirlo/medirlo.

## 6. Puertas de aceptación

- **Automatizado:** grafo, referencias, GLSL sintáctico, ZIP reproducible y CI aprobados.
- **Renderer:** ShaderC carga sin errores y efectos visibles coherentes en OpenGL y, si disponible, Vulkan.
- **Arte:** mejora clara respecto a v7, preservación de texturas, nubes y cielos coherentes, luces no falsas, contornos elegantes, sin UI rota.
- **Publicación:** aprobación humana. Ningún PR de esta fase debe fusionarse ni publicarse por sí solo.
