# NotVisuals — Roadmap de desarrollo

## Prioridad obligatoria: VISUAL → OPTIMIZACIÓN → COMPATIBILIDAD

La fase actual es **visual**. No hay trabajos de ports ni una campaña de FPS. `main` conserva v7; `feat/v8-ink-and-light` es una candidata en desarrollo.

### v8 — Ink & Light

| Sistema | Estado en la rama candidata | Falta para aceptación |
| --- | --- | --- |
| Shape & Shade | Contorno sombreado aparente derivado del color | Sombreado de caras geométrico, oclusión/contacto verificable |
| Inkline | Primer contorno fino por diferencia de luminancia | Máscara de profundidad, estabilidad, HUD, hojas y transparencias |
| Chromaglow | Selección selectiva RGB de emisores aparentes | Pruebas de antorchas/lava/almas, eliminación de falsos positivos |
| Cloudcraft | Máscara de nubes heredada de v7 | Intervención segura en `core/clouds.*`, test OIT/FOG |
| Skyflow | Correcciones globales heredadas de v7 | Tratamiento real del cielo por render path de 26.3 |
| Toon Grade | Posterización moderada de medios tonos | Ajuste artístico sobre escenas reproducibles |
| Integración / QA | Grafo 26 pases + CI estático + ZIP | Runtime OpenGL y Vulkan, screenshots v7/v8/Vanilla |

**Estado:** desarrollo parcial, no release. Ver [informe](V8_IMPLEMENTATION_REPORT.md) y [guía](V8_TESTING_GUIDE.md).

### Salida de la fase visual

- Compilar y activar en cliente real Minecraft 26.3.
- Obtener comparaciones capturadas con la misma escena, cámara y ajustes.
- Verificar que no hay pantallas negras, UI rota, halos excesivos, pérdidas de color ni flicker.
- Iterar cada sistema hasta alcanzar un Gold Master artístico aprobado.
- Solo entonces publicar release.

## Fase 2 — Optimización (no iniciada)

Medir GPU, VRAM y frame pacing, reducir coste de targets/pasadas manteniendo el resultado visual aprobado.

## Fase 3 — Compatibilidad (no iniciada)

Investigar otras versiones cuando el estilo y rendimiento de referencia estén consolidados. Cada port requiere validación separada.
