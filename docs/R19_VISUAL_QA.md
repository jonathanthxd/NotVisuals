# R19 — QA visual final (Minecraft Java 26.3)

**Fase actual: R19.** Objetivo: pulir todos los efectos visuales, no optimizarlos. **No iniciar R20, V9/V10 ni ports** en esta fase. Solo pruebas de calidad/compatibilidad visual básica. Este documento complementa la guía técnica [V8_TESTING_GUIDE.md](V8_TESTING_GUIDE.md).

## Estado de evidencia

- El usuario informa que en sus pruebas cotidianas el aspecto general le resulta correcto; **observó parpadeo en zonas iluminadas del Nether**.
- Esto es feedback de juego, no un certificado de que cada escenario de esta matriz esté probado.
- La última CI valida GLSL, grafos y escenas sintéticas. **No verifica automáticamente ShaderC, transparencias reales, dimensiones, cámara, HUD ni drivers de Minecraft**.
- El atlas y los shaders externos de Aurora Sky requieren autorización antes de redistribución; pruebas locales no equivalen a permiso público.

## A. Pase rápido — imprescindible (15-20 minutos)

| ID | Escena / acción | Comprobación | Resultado |
| --- | --- | --- | --- |
| `NV-R19-01` | Overworld: mediodía, amanecer, atardecer, noche; cámara fija y panorámica | Sin saltos de exposición, cielo roto, doble sol, auroras diurnas involuntarias ni nubes duplicadas | **Pendiente de registrar** |
| `NV-R19-02` | Zona oscura → luz brillante → oscura, repetido | Adaptación suave, sin flashes, blancos quemados ni bombeo de brillo | **Pendiente de registrar** |
| `NV-R19-03` | Nether: glowstone, shroomlight, lava, fuego normal y azul, portal; cámara quieta y movimiento | **Regresión reportada: parpadeo en luces**; identificar qué superficies fallan y cuándo | **Fallo visual reportado; no diagnosticado** |
| `NV-R19-04` | Agua, vidrio, hielo, hojas y niebla; primer/tercer persona | Sin bordes negros, transparencias invertidas, halos extraños ni z-fighting | **Pendiente de registrar** |
| `NV-R19-05` | Mano: antorcha, espada, objeto animado, inventario, HUD, chat, F1, F5 | Sin contornos sobre UI, parpadeo de mano ni cambio brusco de color | **Pendiente de registrar** |
| `NV-R19-06` | `F3+T`, cambio de mundo, dimensión y modo ventana/pantalla completa | Sin pantalla negra, estado de exposición corrupto ni shaders que dejan de cargar | **Pendiente de registrar** |
| `NV-R19-07` | End: cielo, end rods, cristales, portal, entidades oscuras | Sin cambio inesperado de color, halos molestos ni pérdidas de visibilidad | **Pendiente de registrar** |
| `NV-R19-08` | Vanilla vs NotVisuals, con y sin efectos opcionales | Identificar si el problema pertenece al pack, a un efecto opcional o al entorno | **Pendiente de registrar** |

**En cada caso:** anotar `PASS`, `FAIL`, `NOT TESTED` y capturas o vídeo breve. No convertir el feedback general del usuario en PASS automático.

## B. Pruebas que suelen pasarse por alto (segundo pase)

| ID | Escenario específico | Qué detectar |
| --- | --- | --- |
| `NV-R19-09` | Lluvia y tormenta de día/noche; agua desde debajo y desde fuera | Fog, capas superpuestas, rayas/gradientes, cambios raros al emerger |
| `NV-R19-10` | Nubes Fancy/Fast/Off y diferentes render distances | Sol y nubes duplicados, huecos o atlas visible por geometría |
| `NV-R19-11` | Nieve, cuarzo, arena clara y cielo celeste | Falsos emisores y brillo excesivo en superficies no luminosas |
| `NV-R19-12` | Textos, partículas, pociones, portal, fuego y cristal tintado | Postprocesado encima de GUI, sprites con alpha incorrecta o halos cuadrados |
| `NV-R19-13` | Ciclo día/noche natural sin comandos y 15-30 segundos frente a una fuente | Cambios de exposición a saltos y parpadeo temporal |
| `NV-R19-14` | Cambiar FOV, tamaño de ventana, resolución, fullscreen, F3+T | Bordes cortados, desplazamientos, persistencia de render targets |
| `NV-R19-15` | Shader original con pack independiente vs NotVisuals integrado, misma escena | Confirmar la apariencia sin alterar su origen; no distribuir materiales sin permiso |
| `NV-R19-16` | Solo Vanilla 26.3 vs Vanilla + NotVisuals; después mods habituales | Separar errores del pack de incompatibilidades con Sodium/otros mods |
| `NV-R19-17` | Nether: biomas crimson/warped y basalt, soul fire, lava en movimiento | Parpadeos sensibles a color cálido/frío, partículas e iluminación animada |
| `NV-R19-18` | Activar `depth_lab` y `depth_ink` por separado | Siluetas, mano, hojas, transparencia, profundidad invertida; nunca concluir por ambos activados simultáneamente |

## C. Protocolo para el parpadeo del Nether — `NV-R19-03`

1. Seleccionar una escena **reproducible** donde la luz parpadee. Anotar versión exacta 26.3, mods, API/renderizador, GPU, pack(s) activos, coordenadas o semilla si puede compartirse.
2. Grabar **10-20 segundos con cámara fija**, luego **10-20 segundos moviendo la cámara lentamente** y otro clip mirando directamente la fuente emisiva.
3. Comparar tres condiciones con misma escena: **Vanilla sin pack**, **NotVisuals base sin efectos opcionales** y **NotVisuals con el opcional que suelas usar** (si aplica). Evitar superposición de resource packs que reemplacen shaders.
4. Separar fuentes: **glowstone/shroomlight estáticas**, **lava/fuego animados**, **soul fire**, **portal**. Anotar si ocurre cerca/lejos y si afecta al bloque, al halo o a toda la pantalla.
5. Probar `F3+T` y luego entrar/salir del Nether: ¿desaparece, aparece o empeora? Cualquier reinicio de estado temporal es relevante.
6. Si es seguro y reproducible, repetir en modo ventana y fullscreen; capturar `.minecraft/logs/latest.log` después del problema.
7. **No atribuir causa sin evidencia.** Hipótesis a investigar: adaptación temporal (`exposure_adapt.fsh` + historial persistente), extracción de highlights (`highlight_extract.fsh`), composición de bloom, transparencias/partículas o recursos de renderizado. Estas son rutas de diagnóstico, **no fallos demostrados**.
8. Cerrar el issue solo si un cambio real elimina la reproducción y también pasa las escenas de Overworld/End (sin romper el estilo).

## D. Revisión de aceptación

- **P0 antes de merge/publicación:** sin pantalla negra, error ShaderC, fallo de integridad/pack, defectos severos o material ajeno no autorizado.
- **P1 antes de declarar pulido R19:** resolver el parpadeo reproducible del Nether; proteger mano/HUD/transparencias; evitar dobles nubes/sol; exposición estable.
- **P2 calidad artística:** suavidad de auroras/cielo, color del amanecer, glow equilibrado y ausencia de falsos emisores notables.
- **Fuera de R19:** optimización de FPS/VRAM/latencia, reducciones de pases, puertos, iluminación global RGB o sombras geométricas nuevas.

## E. Formato corto para reportar

```text
R19 QA | NV-R19-XX | PASS / FAIL / NOT TESTED
Minecraft exacto: 26.3 (indicar subversión)
Renderizador / mods / GPU:
Paquetes activos y orden:
Dimensión y escena:
Condiciones: hora, clima, FOV, resolución y opciones
Pasos reproducibles:
Esperado vs observado:
¿Pasa sin NotVisuals?:
¿Pasa sin efectos opcionales?:
Vídeo / capturas:
latest.log (si hay error):
```

**No subir logs con tokens, direcciones privadas u otra información sensible sin revisarlos.**

Evidencias y reportes deben reunirse en un issue de QA R19; no se certifica una prueba sin evidencias reales.
