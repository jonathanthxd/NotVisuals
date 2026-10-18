# Renderer architecture — v7 baseline

## Pack entry points

- `pack.mcmeta` — Minecraft pack metadata (format range `[97, 1]` to `[97, 1]`, targeting 26.3 in this baseline).
- `assets/minecraft/post_effect/end_of_frame.json` — automatic chain executed by the renderer while the pack is active.
- `assets/notvisuals/post_effect/pixel_vivid.json` — optional command-applied pixel effect.
- `assets/notvisuals/post_effect/soft_glow.json` — optional command-applied glow effect.
- `assets/notvisuals/shaders/post/*.fsh` — original fragment shader source.

## Pipeline overview

The automatic chain uses persistent 1×1 exposure history, multiple full-screen intermediate targets, a set of blur passes and compositing stages. It samples `minecraft:main` and writes the final result back to it.

Core components in the v7 source:

1. Measure scene brightness and adapt exposure across frames.
2. Derive atmosphere and selected cloud/highlight components from the rendered image.
3. Produce and combine multi-scale bloom.
4. Apply adaptive pixel styling and colour/finishing passes.
5. Write the final image back to the main render target.

Read the JSON pass sequence for the **authoritative** order. The reference build contains 11 custom fragment shaders and 24 passes in the automatic chain.

## Constraints

- Fragment post-processing cannot assume access to true scene normals, material properties or shadow maps.
- Colour-derived masks can misidentify bright blocks, snow, sky and water.
- Multiple full-screen passes can be bandwidth intensive even with a tiny packaged ZIP.
- Shader compilation, driver support, blend behaviour and actual FPS require runtime testing.

## Change discipline

- Treat v7 as an immutable visual baseline; make changes in reviewable branches.
- For every visual iteration: define expected appearance, validate JSON/shader references, test in game, capture matched screenshots and inspect `latest.log`.
- Defer compatibility ports until the visual and optimisation phases are finished.
