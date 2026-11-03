# NotVisuals v8 — Candidate 3: Aurora Sky

**Estado:** candidata experimental, no release oficial; rama `feat/v8-ink-and-light` y PR #1. Candidate 2 continúa como base del pipeline de postprocesamiento. Las pruebas automatizadas y el ZIP no sustituyen la validación dentro de Minecraft 26.3.

## Integración elegida

La prueba aportada por el propietario usaba el pack Aurora/Cielo por encima de NotVisuals Candidate 2, con Sodium, ModernFix y FerriteCore. Se conservaron sus shaders y la textura **original y exacta** de la sky sheet. El cielo personalizado es el protagonista; el postprocesamiento de NotVisuals sigue actuando encima. No se añadieron mods obligatorios.

- `assets/minecraft/shaders/core/sky.vsh` + `sky.fsh`: control del sky pass, con comportamiento de Skyflow de Candidate 2 preservado para las rutas no interceptadas.
- `core/position_tex.vsh` + `position_tex.fsh`: interceptan la geometría solar y proyectan una hoja de seis caras de día/noche; la hoja contiene nubes pintadas y auroras nocturnas.
- `core/stars.vsh` y `core/position_color.vsh`: suprimen elementos de estrellas y resplandor de amanecer Vanilla para evitar duplicados.
- `core/clouds.vsh`: descarta la geometría de nubes Vanilla para evitar doble capa; **no es necesario cambiar manualmente el ajuste de nubes** si el override se carga correctamente.
- `core/clouds.fsh`: permanece para mantener la interfaz de la etapa de nubes y OIT de 26.3.
- `assets/minecraft/textures/environment/celestial/sun.png`: atlas del cielo de **3080 × 4064**, no un sprite solar corriente. Incluye día, noche y auroras. **No reemplazar por un PNG transparente**, pues se perdería el cielo.
- `assets/minecraft/post_effect/end_of_frame.json`: conserva las 21 pasadas de Candidate 2, bloom y estilo existentes.

## Almacenamiento reproducible del atlas

La transferencia binaria directa mediante el conector no soportó el PNG original de ~6,7 MB. En Git, el atlas se conserva **sin pérdida** como 15 fragmentos Base64 bajo `source/aurora_sky/sun_atlas/`. `scripts/sky_atlas.py` reconstruye `sun.png` antes del empaquetado y valida:

- Tamaño original: 3080 × 4064.
- SHA-256 del PNG exacto: `06cd49d8d53e5855e90d657cb6aa65d1a9d08954374dce0158ef5f846e990c00`.
- Firma PNG, integridad Base64 y cantidad de partes.

`python3 scripts/build_pack.py` crea `dist/NotVisuals_26.3_v8_candidate_3_AuroraSky.zip`. La textura generada se excluye de Git para evitar duplicar el archivo de 6,7 MB y evitar que cambios locales casuales sustituyan el arte original. El ZIP de pruebas generado **localmente** contiene el PNG íntegro en la ruta esperada por Minecraft. CI comprueba la compilación pero **no publica un ZIP descargable** hasta verificar los permisos de los recursos aportados por terceros; consultar [RIGHTS_STATUS.json](RIGHTS_STATUS.json). No hay reducción de paleta ni recomposición artística del atlas.

## Limitaciones importantes

- El cielo se basa en una sky sheet con auroras **dibujadas en la textura**, no en simulación volumétrica ni auroras físicas generadas procedimentalmente.
- La sustitución utiliza core shaders no soportados como API estable por Mojang y detección del quad solar dependiente de la implementación. Otros resource packs que sobrescriban estas rutas pueden interferir.
- La geometría de nubes Vanilla se oculta desde el vertex shader; verificar OIT, clima, Fancy/Fast/Off y distintas distancias de cámara dentro del cliente 26.3.
- No se han añadido mejoras a sombras geométricas, SSAO ni a materiales de Chromaglow en esta candidata.
- El funcionamiento observado por el propietario corresponde a **dos packs superpuestos**; que el pack unificado cargue, compile y reproduzca ese aspecto requiere pruebas reales.
- La procedencia/licencia de los shaders y del atlas proporcionados por un tercero debe confirmarse antes de fusionar en `main` o distribuir oficialmente. El hecho de recibirlos no demuestra permiso de redistribución. El bloqueo se aplica mediante `python3 scripts/build_pack.py --release`; no se levantará hasta verificar evidencias y actualizar el manifiesto.

## Pruebas manuales esenciales

1. Instalar la Candidate 3 ZIP como **único** pack que sobrescriba shaders. Desactivar el viejo `Cielo_test` y Candidate 2 para no superponer efectos.
2. Mantener inicialmente las nubes de Minecraft en **Fancy u ON** para confirmar que no se duplican con las nubes de la sky sheet.
3. Día: cielo y nubes de la hoja deben verse como en la prueba original, sin bloom descontrolado.
4. Noche: auroras visibles, sin duplicación de estrellas Vanilla ni artefactos azules.
5. Amanecer/atardecer: sin doble sol, salto de brillo o resplandor de amanecer Vanilla superpuesto.
6. Lluvia, tormenta, dimensión Nether/End, agua y cielo visto con FOV amplio: sin pantallas negras, huecos, halos ni sky sheet fuera de lugar.
7. Verificar con Sodium + ModernFix + FerriteCore; repetir solo Vanilla si es posible para distinguir incompatibilidades.
8. Revisar `.minecraft/logs/latest.log` tras activar y tras F3+T; conservar capturas Vanilla, Candidate 2 + Cielo_test y Candidate 3.
9. Depth Lab/Depth Ink siguen siendo opcionales e independientes; no es necesario activarlos para evaluar Aurora Sky.

**Puertas de aceptación:** CI de sintaxis y paquete → compilación ShaderC y carga real → comparación visual sobre escenas emparejadas → permiso de redistribución de recursos de tercero → aprobación explícita del propietario.
