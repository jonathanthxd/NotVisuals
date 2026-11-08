# NotVisuals v8 — R20 Visual Polish

**Base:** Full user-provided experimental R19 archive (724 assets, 41 GLSL sources, 41 postprocessing passes). Original baseline remains locked in `docs/R19_SOURCE_MANIFEST.json`; precisely five purposeful R20 shader edits are recorded with SHA-256 in [R20_CHANGESET.json](R20_CHANGESET.json).

## Visual-only changes

- **Pink Radiance marker specks:** broaden low-opacity AA candidate detection only when an *exact* encoded marker class is found within a compact 2-pixel neighbourhood. Ordinary pink blocks without an encoded neighbour are passed through untouched.
- **Source-seed consistency:** snap selected Radiance source UV to the precise source framebuffer texel centre instead of fractional sub-cell probe coordinates. This reduces seed-coordinate wobble from subpixel camera motion.
- **Nether emission flicker:** gently strengthen depth-/hue-validated temporal blending of light energy, with narrower amplitude bounds. Hue, class definitions and light radii do not change; motion-vector-free limitations remain.
- **Outline polish:** guard almost-black pixels against repeated depth-ink plus Inkline darkening. Main silhouette parameters and pipeline remain intact.
- **Sun / moon bloom:** modestly soften only their *wide* corona tails ahead of the existing bloom chain; celestial discs, core halo and normal block emission bloom are unchanged.

## Preservation and distribution

- No new effects, render passes, shaders, marker classes, model overrides, textures or optimizations. Full RGB profiles 1–53, auroras, animated ores, Water Lilies, atmospheric textures, Depth Ink and other accepted systems remain available.
- Preserves **MIT** author notices for Animated Ore and Water Lilies, [Aurora Sky creator credit](../CREDITS.md), project GPLv3 / CC BY-NC-SA policies and the original R18 credit.
- GitHub hosts **source** under `src/pack/`; the official installable ZIP is intended for **[Modrinth](https://modrinth.com/resourcepack/notvisuals)**, not GitHub Releases. Others retain the redistribution rights conferred by the licenses.

## Validation status

The code changes receive static pipeline/asset verification, regression tests and edited-fragment GLSL compilation against the pinned 26.3 reference in GitHub CI. **These tests do not reproduce or certify actual Minecraft gameplay**. The R19 source is preserved verbatim except for Git's reversible CRLF→LF text canonicalization and the five declared edits.

**Manual acceptance still required before public Modrinth version:** test Nether lava/glowstone/shroomlight/soul fire, coloured ores and pink specks during camera movement, outline on foliage/hand/water, daytime and twilight sun and nighttime moon, F3+T, dimensions and ShaderC log. The author has not supplied in-game R20 evidence, so do **not** claim a confirmed flicker fix or full visual approval solely from CI.

See [R20 visual acceptance checklist](R20_VISUAL_REVIEW.md).
