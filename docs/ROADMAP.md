# NotVisuals — Roadmap

Prioridad: **calidad visual → optimización → compatibilidad**. Rama experimental
`feat/v8-ink-and-light`, PR #1; v7 en `main` permanece intacta.

| Sistema | Estado de candidata 2 | Falta para aceptación |
| --- | --- | --- |
| Depth Stability | Muestreo exacto, rechazo de inválidos y soporte tangencial; tests sintéticos | Reproducir flicker de mano y comparar vídeos; validar depth real y transparencias |
| Skyflow | Fragment específico de cielo, curva de horizonte y tintes acotados | Carga ShaderC y calibración día/ocaso/noche/clima |
| Cloudcraft | Fragment específico de nubes, color por cara, cobertura OIT conservada | Fancy Clouds en juego, siluetas más suaves si son viables |
| Chromaglow | Kernel original + contexto de superficies extensas; color conservado | Confirmar fuentes reales y falsos positivos de nieve/cuarzo |
| Inkline | RGB automático conservado; depth oscuro optativo | Mano/HUD, foliaje, agua, entidades y estabilidad en movimiento |
| Shape & Shade | Sombreado aparente de imagen | Datos geométricos fiables; no se han implementado sombras proyectadas/SSAO |
| Toon Grade | Primera candidata conservada | Capturas comparables y aprobación artística |
| QA automatizada | 21 pruebas locales, 40 compilaciones GLSL, ZIP determinista | Verificar ejecución remota CI; runtime Minecraft y revisión del propietario |

NV-SKY-001, NV-DEPTH-001/002, NV-GLOW-001/002, NV-CLOUD-001 y NV-SKY-002
permanecen abiertos hasta evidencia visual adecuada. Los tests sintéticos prueban
propiedades concretas de código, sin cerrar la aceptación dentro de Minecraft.

Siguiente paso: ejecutar [la guía](V8_TESTING_GUIDE.md), recoger latest.log y
vídeos/capturas Vanilla/v7/v8.1/v8.2. No fusionar, publicar release o actualizar
Modrinth sin aceptación expresa.

La optimización de GPU/VRAM y los ports se mantienen aplazados.
