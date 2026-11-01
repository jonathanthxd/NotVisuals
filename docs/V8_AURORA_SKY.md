# NotVisuals v8 Candidate 3 — Aurora Sky

## Motivo
El usuario probó `Cielo_test.zip` por encima de Candidate 2 en Minecraft
Java 26.3 con Sodium, ModernFix y FerriteCore y prefiere su cielo diurno
ilustrado y sus auroras nocturnas. La Candidate 3 une esos dos packs
sin rediseñar ni cambiar el atlas que ya fue evaluado visualmente.

## Arquitectura
- `position_tex.vsh/.fsh`: detectan el quad del sol, comprueban marcadores
  de `sun.png` y proyectan un atlas cubemap de día y noche.
- `sun.png`: NO es una textura convencional del sol. Es el atlas real
  3080 x 4064 (celestial); cambiarlo por 1x1 transparente rompe las auroras.
- `sky.vsh/.fsh`: puente del cielo y fallback Skyflow Candidate 2.
- `stars.vsh` y `position_color.vsh`: evitan superposición con las
  estrellas y el resplandor del amanecer de Vanilla en la ruta de cielo.
- `clouds.vsh`: oculta la geometría de nubes Vanilla para que no se
  dupliquen las formas dibujadas en el atlas. Se conserva `clouds.fsh`
  de Candidate 2 para mantener el contrato de su etapa fragment/OIT.
- Se conservan las 21 pasadas automáticas de Candidate 2, Chromaglow,
  Toon Grade, Depth Lab opcional y Depth Ink opcional.

## Transferencia sin pérdida
El atlas PNG original proporcionado pesa 6 704 079 bytes. Su SHA256 es:

`06cd49d8d53e5855e90d657cb6aa65d1a9d08954374dce0158ef5f846e990c00`

La fuente se conserva en 15 archivos ASCII `source/aurora_sky/sun_atlas/part_*.b64`.
`scripts/sky_atlas.py` los reconstruye y comprueba el SHA256/las dimensiones,
produciendo `assets/minecraft/textures/environment/celestial/sun.png`.
El paquete distribuido contiene únicamente el PNG original, no las partes
base64. Si se decide registrar el PNG directamente en Git, no eliminar las
partes fuente sin actualizar el proceso de construcción.

## Calidad y riesgos
- Verificar dentro del juego: día, ocaso, noche/auroras, lluvias, nubes
  activadas en ajustes, sol/luna, Nether/End y recursos de otros packs.
- El algoritmo original usa heurísticas de geometría, distancias y
  `gl_VertexIndex`; esa interfaz NO es pública estable.
- Se espera que el pack oculte las nubes Vanilla automáticamente, pero
  la ausencia de ShaderC runtime impide considerarlo confirmado.
- El atlas fuente contiene colores RGB en píxeles con alpha casi cero:
  no modificar alpha ni optimizar la imagen eliminando canales ocultos.
- Los shaders/atlas provenían de un amigo, y el código menciona
  `createtextures.com/tools/sky`. **No se ha verificado permiso de
  redistribución pública o licencia.** Mantener la integración experimental
  y aclarar la procedencia antes de fusionar/publicar.
