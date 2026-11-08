# NotVisuals

**Vanilla graphics, reimagined.**

Resource pack gráfico para **Minecraft Java Edition 26.3** que utiliza `minecraft:end_of_frame` y shaders GLSL de postprocesamiento. No requiere Iris, OptiFine ni un shader loader.

**Estado de esta rama:** **v8 — Ink & Light, candidata 3: Aurora Sky (experimental).** El código y la validación estática no equivalen a una compilación completa dentro de Minecraft ni a una aprobación visual. `main` continúa siendo la referencia estable v7.

[Modrinth (v7 publicada)](https://modrinth.com/resourcepack/notvisuals) · [Errores](https://github.com/jonathanthxd/NotVisuals/issues) · [Guía de pruebas v8](docs/V8_TESTING_GUIDE.md) · [Informe de implementación](docs/V8_IMPLEMENTATION_REPORT.md)

## Funciones implementadas en esta candidata

- Exposición adaptativa y corrección cromática heredadas de v7.
- Bloom multinivel con **Chromaglow v8**, extracción conservadora a dos escalas, con respuesta adicional a superficies extensas y tintes cálidos/fríos aproximados. No identifica bloques ni simula luz coloreada real.
- **Inkline v8**: sombreado de contacto aparente y líneas finas basadas en contraste local de imagen. No son sombras proyectadas geométricas ni contornos por ID de objeto.
- **Toon Grade v8**: ligera cuantización tonal de medios tonos con protección de altas luces y zonas oscuras.
- Pixelación adaptativa, atmósfera y acabado original heredados de v7.
- **Aurora Sky (Candidate 3):** atlas de cielo día/noche con auroras y nubes artísticas, integrado mediante core shaders sobre los efectos de Candidate 2. Los shaders ocultan nubes Vanilla duplicadas. El atlas original se reconstruye sin pérdida antes de empaquetar. Consulta [integración Aurora Sky](docs/V8_AURORA_SKY.md).
- **Depth Ink**, contorno oscuro **optativo**, y **Depth Lab**, efecto **optativo** para visualizar discontinuidades del `minecraft:main` depth buffer. Su comportamiento real con OIT, Vulkan y OpenGL sigue pendiente de validación.
- Validación de grafos, samplers e includes; tests de buffers GLSL sintéticos opcionales y ZIP reproducible. Consulta la guía para instalar dependencias GPU y ejecutar las 21 pruebas completas; la construcción básica sigue usando solo stdlib.

**Sin verificar en Minecraft como pack unificado:** los nuevos core overrides, la estética de cielo/nubes, la respuesta por bloque emisor y el flicker de mano. Se eliminó la selección de blancos como nubes del postprocess automático. No hay sombreado geométrico de terreno, SSAO ni identificación fiable de materiales; Chromaglow sigue siendo una aproximación RGB. Consulta el [informe de candidata 2](docs/V8_IMPLEMENTATION_REPORT.md) y la [investigación de referencias](docs/V8_REFERENCE_RESEARCH.md).

## Instalación y pruebas

Desde esta rama:

```bash
python3 scripts/validate_pack.py
python3 -m unittest discover -s scripts -p 'test_*.py' -v
python3 scripts/build_pack.py  # build experimental para pruebas locales
# python3 scripts/build_pack.py --release  # BLOQUEADO hasta obtener autorizaciones
```

El resultado se genera en `dist/NotVisuals_26.3_v8_candidate_3_AuroraSky.zip`. CI construye y comprueba la candidata, pero **no publica el ZIP como artefacto descargable** mientras haya recursos externos con derechos no verificados. Para pruebas locales, utiliza el archivo generado por `scripts/build_pack.py` en tu entorno autorizado; no lo redistribuyas. Colócalo **sin extraer** en `.minecraft/resourcepacks/` y pruébalo en **Minecraft 26.3**. La publicación oficial requiere `python3 scripts/build_pack.py --release` y cerrar las comprobaciones de licencias.

El efecto base es automático. El laboratorio de profundidad es optativo:

```mcfunction
/posteffect add @s notvisuals:depth_lab
/posteffect list @s
/posteffect remove @s notvisuals:depth_lab
```

El contorno por profundidad oscuro se activa con `/posteffect add @s notvisuals:depth_ink` y se retira con `/posteffect remove @s notvisuals:depth_ink`. Pruébalo separado del laboratorio; ambos usan datos de profundidad aún experimentales.

Otros efectos opcionales heredados: `notvisuals:pixel_vivid` y `notvisuals:soft_glow`. Evita encenderlos simultáneamente durante comparaciones controladas.

**Atención:** el postprocesamiento puede afectar parcialmente a HUD/partículas; la máscara perfecta de interfaz aún no existe. Si aparecen pantallas negras, errores ShaderC o problemas de transparencia, desactiva la candidata y conserva `latest.log`.

## R19 — Último pulido visual (fase actual)

El usuario ha informado que el pack se ve bien en las pruebas habituales, con **parpadeo de algunas luces en el Nether** como defecto conocido. Este feedback no equivale a QA completa.

- [Pruebas dirigidas R19 y pasos reproducibles](docs/R19_VISUAL_QA.md)
- [Estado y alcance de R19](docs/R19_STATUS.md)
- [Solicitud de permiso al autor de Aurora Sky](docs/AURORA_SKY_PERMISSION.md)

**No se trabaja en optimización todavía**; el rendimiento/VRAM y los ports quedan pospuestos (posiblemente V9/V10). No distribuir Aurora Sky hasta confirmar derechos.

## Desarrollo y estado técnico

- [Arquitectura y dependencias](docs/ARCHITECTURE.md)
- [Dirección visual v8](docs/VISUAL_DIRECTION_V8.md)
- [Informe de implementación](docs/V8_IMPLEMENTATION_REPORT.md)
- [Matriz y guía de testing](docs/V8_TESTING_GUIDE.md)
- [Roadmap](docs/ROADMAP.md)
- [Aurora Sky — Candidate 3](docs/V8_AURORA_SKY.md)

La raíz del repositorio es directamente la raíz del resource pack. `pack.mcmeta` y `pack.png` deben quedar en la raíz del ZIP. No se incluyen tests, documentación de desarrollo ni Git en la distribución; sí los avisos de licencia y atribución.

**Orden de prioridades:** máxima calidad visual → optimización sin pérdida visual → compatibilidad entre versiones.

## Licencia y procedencia

NotVisuals distingue **código original GPL-3.0-only** y **recursos artísticos originales CC BY-NC-SA 4.0**, sujetos a la verificación de los derechos correspondientes. El conjunto no es totalmente Open Source según la definición OSI.

La procedencia de parte del atlas y los shaders de **Aurora Sky todavía está sin verificar**. Ninguna licencia nueva del proyecto se atribuye automáticamente a esos componentes; deben autorizarse o sustituirse antes de publicar R20. Los permisos GPL de versiones históricas siguen vigentes.

La comprobación automática utiliza [el registro de derechos](docs/RIGHTS_STATUS.json); el comando `--release` impide publicar mientras los permisos conocidos sigan pendientes.

Consulta [LICENSING.md](LICENSING.md), [LICENSE-CODE](LICENSE-CODE), [LICENSE-ASSETS.md](LICENSE-ASSETS.md), [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md), [CONTRIBUTING.md](CONTRIBUTING.md) y [Modrinth](docs/MODRINTH_LICENSING.md).

Proyecto independiente, sin afiliación con Mojang Studios/Microsoft.
