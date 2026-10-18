# NotVisuals

**Vanilla graphics, reimagined.**

Resource pack gráfico para **Minecraft Java Edition 26.3** que utiliza `minecraft:end_of_frame` y shaders GLSL de postprocesamiento. No requiere Iris, OptiFine ni un shader loader.

**Estado de esta rama:** **v8 — Ink & Light, candidata 2 experimental.** El código y la validación estática no equivalen a una compilación completa dentro de Minecraft ni a una aprobación visual. `main` continúa siendo la referencia estable v7.

[Modrinth (v7 publicada)](https://modrinth.com/resourcepack/notvisuals) · [Errores](https://github.com/jonathanthxd/NotVisuals/issues) · [Guía de pruebas v8](docs/V8_TESTING_GUIDE.md) · [Informe de implementación](docs/V8_IMPLEMENTATION_REPORT.md)

## Funciones implementadas en esta candidata

- Exposición adaptativa y corrección cromática heredadas de v7.
- Bloom multinivel con **Chromaglow v8**, extracción conservadora a dos escalas, con respuesta adicional a superficies extensas y tintes cálidos/fríos aproximados. No identifica bloques ni simula luz coloreada real.
- **Inkline v8**: sombreado de contacto aparente y líneas finas basadas en contraste local de imagen. No son sombras proyectadas geométricas ni contornos por ID de objeto.
- **Toon Grade v8**: ligera cuantización tonal de medios tonos con protección de altas luces y zonas oscuras.
- Pixelación adaptativa, atmósfera y acabado original heredados de v7.
- **Skyflow y Cloudcraft**: fragments específicos de cielo/nubes de 26.3, con tintes contenidos y cobertura OIT conservada. Sin nubes volumétricas ni formas redondeadas nuevas.
- **Depth Ink**, contorno oscuro **optativo**, y **Depth Lab**, efecto **optativo** para visualizar discontinuidades del `minecraft:main` depth buffer. Su comportamiento real con OIT, Vulkan y OpenGL sigue pendiente de validación.
- Validación de grafos, samplers e includes; tests de buffers GLSL sintéticos opcionales y ZIP reproducible. Consulta la guía para instalar dependencias GPU y ejecutar las 21 pruebas completas; la construcción básica sigue usando solo stdlib.

**Sin verificar en Minecraft:** los nuevos core overrides, la estética de cielo/nubes, la respuesta por bloque emisor y el flicker de mano. Se eliminó la selección de blancos como nubes del postprocess automático. No hay sombreado geométrico de terreno, SSAO ni identificación fiable de materiales; Chromaglow sigue siendo una aproximación RGB. Consulta el [informe de candidata 2](docs/V8_IMPLEMENTATION_REPORT.md) y la [investigación de referencias](docs/V8_REFERENCE_RESEARCH.md).

## Instalación y pruebas

Desde esta rama:

```bash
python3 scripts/validate_pack.py
python3 -m unittest discover -s scripts -p 'test_*.py' -v
python3 scripts/build_pack.py
```

El resultado se genera en `dist/NotVisuals_26.3_v8_candidate_2.zip`. El workflow prepara el artefacto temporal `NotVisuals-26.3-v8-candidate-2` tras pasar CI; comprueba su ejecución antes de descargarlo. Colócalo **sin extraer** en `.minecraft/resourcepacks/`, selecciónalo y prueba en **Minecraft 26.3**, idealmente comparándolo con v7 y Vanilla.

El efecto base es automático. El laboratorio de profundidad es optativo:

```mcfunction
/posteffect add @s notvisuals:depth_lab
/posteffect list @s
/posteffect remove @s notvisuals:depth_lab
```

El contorno por profundidad oscuro se activa con `/posteffect add @s notvisuals:depth_ink` y se retira con `/posteffect remove @s notvisuals:depth_ink`. Pruébalo separado del laboratorio; ambos usan datos de profundidad aún experimentales.

Otros efectos opcionales heredados: `notvisuals:pixel_vivid` y `notvisuals:soft_glow`. Evita encenderlos simultáneamente durante comparaciones controladas.

**Atención:** el postprocesamiento puede afectar parcialmente a HUD/partículas; la máscara perfecta de interfaz aún no existe. Si aparecen pantallas negras, errores ShaderC o problemas de transparencia, desactiva la candidata y conserva `latest.log`.

## Desarrollo y estado técnico

- [Arquitectura y dependencias](docs/ARCHITECTURE.md)
- [Dirección visual v8](docs/VISUAL_DIRECTION_V8.md)
- [Informe de implementación](docs/V8_IMPLEMENTATION_REPORT.md)
- [Matriz y guía de testing](docs/V8_TESTING_GUIDE.md)
- [Roadmap](docs/ROADMAP.md)

La raíz del repositorio es directamente la raíz del resource pack. `pack.mcmeta` y `pack.png` deben quedar en la raíz del ZIP. No se incluyen tests, documentación ni Git en la distribución.

**Orden de prioridades:** máxima calidad visual → optimización sin pérdida visual → compatibilidad entre versiones.

## Licencia

GPL-3.0; consulta [LICENSE](LICENSE). Proyecto independiente, no afiliado a Mojang Studios/Microsoft.
