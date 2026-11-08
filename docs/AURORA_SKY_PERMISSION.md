# R19 — Aurora Sky: autorización y procedencia

**Estado: PENDIENTE.** Los archivos llegaron por Discord de un amigo, pero el usuario no ha confirmado que sea autor o titular de los derechos. Esto **no es autorización** y no cambia el estado del registro [RIGHTS_STATUS.json](RIGHTS_STATUS.json).

## Material que debemos identificar

- Atlas de cielo, nubes y auroras (archivo PNG original). En el repositorio se almacena como `source/aurora_sky/sun_atlas/part_*.b64` y se genera `assets/minecraft/textures/environment/celestial/sun.png`, SHA-256 `06cd49d8d53e5855e90d657cb6aa65d1a9d08954374dce0158ef5f846e990c00`.
- Shaders compartidos en Discord que sirvieron de base a los overrides de `assets/minecraft/shaders/core/`. **No atribuir toda la carpeta al amigo** sin cotejar sus archivos originales y las partes creadas en NotVisuals.
- Otros fragmentos, texturas, bibliotecas o recursos ajenos incorporados por el autor original, si existen.

## Mensaje sugerido para enviar por Discord (ES)

> ¡Hey! Te escribo por el cielo/las auroras y los archivos de shaders que me compartiste para mi resource pack NotVisuals. Me encantó cómo quedaron y quiero publicar el pack en GitHub y Modrinth, así que prefiero confirmar los permisos contigo.
>
> ¿El atlas/imagen y esos shaders los creaste tú y tienes derecho a autorizar su publicación, o hay partes de otra persona? Si usaste recursos de terceros, ¿me puedes decir cuáles y sus licencias?
>
> Si son tuyos, ¿me autorizas a **usar, adaptar y redistribuir públicamente** el atlas en NotVisuals bajo **CC BY-NC-SA 4.0** (permite compartir y modificar con crédito, sin uso comercial, y manteniendo esa licencia), y los shaders que tú hayas escrito bajo **GPLv3** (permite estudio, forks, modificación y uso comercial del código bajo sus condiciones)? Esto supone dar permisos también a otros usuarios, no solo a mí.
>
> Si prefieres otra licencia o solo autorizarme a incluirlos en el pack, dímelo y lo documentamos antes de publicar.
>
> ¿Cómo te gustaría aparecer en los créditos (nombre/alias/enlace)? Gracias de nuevo 💙

**Nota:** Si hay autorización únicamente para incluir el archivo en el pack, **NO** indicar que el autor lo licenció bajo CC BY-NC-SA ni GPLv3. Documentar la licencia/permiso propio y comprobar compatibilidad para cualquier modificación o combinación de código. Si no hay autorización suficiente, sustituir el contenido.

## Optional English wording

> Hey! I'm preparing a public release of NotVisuals on GitHub and Modrinth, which includes the sky/aurora artwork and shaders you sent me on Discord. Did you create and own the rights to all of these files, or are any elements from third parties? If you own the rights, would you explicitly agree to distribute your original sky artwork under **CC BY-NC-SA 4.0** and your original shader code under **GPLv3** as part of NotVisuals, including allowing other people to copy, modify and share them under those licenses? If not, please tell me which usage/redistribution rights you are comfortable granting. How should I credit you?

## Proceso de verificación (no saltarse pasos)

1. Confirmar identidad del emisor en Discord y cuáles son los **archivos originales concretos**. Guardar mensaje original, fecha y correspondencia con el atlas/hash y los shaders, en archivo privado.
2. Confirmar autoría y titularidad; pedir aclaración de recursos de terceros (incluidos recursos creados en empleo o para un cliente, o sacados de paquetes de terceros).
3. Solicitar una respuesta explícita sobre **licencias para el público**, modificación, distribución en GitHub y Modrinth y atribución. Un «úsalos como quieras» ambiguo no establece una licencia pública de GPLv3 o CC BY-NC-SA.
4. Conservar el mensaje de consentimiento, fecha e identidad en una ubicación privada y segura; **no publicar capturas de Discord, IDs ni nombres reales sin permiso**. Para una evidencia pública, solicitar un texto público del autor o publicar un resumen aprobado por él, sin información privada.
5. Comparar los archivos originales con la integración actual para distinguir autoría original, código de terceros y modificaciones propias. Registrar en `THIRD_PARTY_LICENSES.md` cada licencia y crédito.
6. Solo después de acreditar cada material, actualizar los registros de `docs/RIGHTS_STATUS.json` de `pending` a `cleared`, con campos `author`, `origin_url`, `license_or_permission`, `evidence_url` y `reviewed_by`. Usar referencias a evidencia verificable: no inventar URLs ni autores.
7. Ejecutar `python3 scripts/license_audit.py --release` y revisar las condiciones legales reales. La comprobación automática valida la presencia de datos, **no** su autenticidad.
8. Si el autor no tiene derechos o las condiciones no son compatibles, **sustituir** el atlas/shaders problemáticos por originales o con licencias verificadas; después repetir pruebas visuales.

**Fuente legal:** [Creative Commons — License Your Work](https://creativecommons.org/cc-license-your-work/) recomienda aplicar licencias únicamente al material cuyo copyright se posee/controla. La licencia CC es irrevocable una vez concedida. No confundir consentimiento privado, licencia pública y derechos de terceros.

**Bloqueo:** [issue #2](https://github.com/jonathanthxd/NotVisuals/issues/2). Hasta recibir la respuesta del autor, los componentes siguen **PENDING**, aunque la candidata técnica pase CI.
