# R19 — seguimiento de pulido visual

> Estado a 2026-11-08. Este documento resume la evidencia disponible, no acredita pruebas que no se hayan efectuado.

## Decisiones de alcance

- **R19 activo:** últimas correcciones y calibración de calidad visual.
- **R20:** no se inicia automáticamente y no es requisito previo de optimización; debe redefinirse después de la aceptación visual de R19.
- **Optimización:** diferida a una futura versión (posiblemente V9 o V10); no hacer cambios de rendimiento en esta rama sin decisión explícita.
- **No añadir nuevos sistemas** hasta estabilizar los actuales salvo nueva instrucción expresa.

## Estado técnico

| Área | Estado | Evidencia necesaria |
| --- | --- | --- |
| Código gráfico candidato v8 / Aurora Sky | Implementación experimental, CI exitosa | Capturas comparables y pruebas reales en Minecraft 26.3 |
| Overworld / uso cotidiano | Usuario informa experiencia generalmente buena | Registrar al menos `NV-R19-01` y `NV-R19-02` |
| Nether / emisivos | **Parpadeo reportado**; sin causa confirmada | Reproducción dirigida `NV-R19-03`; issue enlazado |
| End / transparencias / mano / HUD | Sin evidencia detallada de cierre | `NV-R19-04` a `NV-R19-08` |
| Licencia del atlas y shaders | **Consentimiento expreso del autor comunicado el 2026-11-08** | Conservar DM privado y atribución; revisar cualquier recurso de terceros |
| Publicación | **No aprobada**: licencia artística registrada, QA y fuente R19 real pendientes | Verificar ZIP R19, QA visual y Modrinth |

## Recursos

- [Guía de QA R19](R19_VISUAL_QA.md)
- [Guía de autorización del amigo](AURORA_SKY_PERMISSION.md)
- [Pruebas técnicas anteriores](V8_TESTING_GUIDE.md)
- [Issue derechos #2](https://github.com/jonathanthxd/NotVisuals/issues/2)

**Distinción importante:** el consentimiento privado recibido incluye expresamente GPLv3 y CC BY-NC-SA 4.0, pero no ha sido comprobado de forma independiente ni sustituye la QA de Minecraft.
