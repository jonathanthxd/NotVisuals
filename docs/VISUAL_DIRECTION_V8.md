# NotVisuals v8 — Ink & Light (visual direction draft)

**Status:** aspirational art direction / technical research plan. Not implemented or runtime-verified.  
**Target:** Minecraft Java 26.3, vanilla resource pack.  
**Priority:** visual fidelity first; optimization second; version ports last.  
**Baseline:** v7 in `main` stays untouched until a tested replacement is approved.

## Intent

Build a distinctive *stylized vanilla* appearance: clearly readable volumes, deliberate ink-like edges, richer directional face shading, restrained toon color separation, vivid yet controlled emissive glow, soft dimensional clouds, and atmospheric skies. This is **not** a bundle or code fork of the references below and is **not** a photorealistic shaderpack.

### Aspirational references, not implementation dependencies

| Project | Takeaway for our art direction | Important boundary |
| --- | --- | --- |
| [ReShaded](https://modrinth.com/resourcepack/re-shaded) | Strong, readable block-face shading and believable apparent shadow | Rebuild independently; do not reuse source/assets |
| [Outline Shader](https://modrinth.com/resourcepack/outline-shader) | Stylized dark/light contour around world geometry and entities | Avoid constant thick outlines or overwhelming UI |
| [Nexus Shaders](https://modrinth.com/resourcepack/nexus-shaders) | Visual depth and layered atmospheric lighting | Some advertised features require mods; not a vanilla guarantee |
| [PeaToons](https://modrinth.com/resourcepack/peatoons-shader-resource-pack) | Cohesive vibrant, illustrated world instead of realism | Establish our own color science and palette |
| [ShaderTech Continued](https://modrinth.com/resourcepack/shadertech-continued) | Differentiated luminous materials and colored halos | Bloom does **not** equal real colored block-light propagation |
| [Fluffy Fancy Clouds](https://modrinth.com/resourcepack/fluffy-fancy-clouds) | Soft-edged, shaded, whimsical clouds | Design own cloud shader for 26.3 renderer; no source copying |
| [Beautified Sky](https://modrinth.com/resourcepack/beautified-sky/gallery) | Sky gradients, horizon, curvature perception, and star treatment | Do not reuse sky art/assets/code |

Each reference has its own license. Design inspiration does not authorize copying any shader source, textures, LUTs or assets. Attribution can acknowledge inspiration but does not replace rights or license compatibility checks.

## V8 visual systems and implementation research

### V8.1 — Shape & Shade (top priority)
- Establish stronger *apparent* face shading, especially walls, overhangs, stone formations, caves and builds, without painting unrelated regions dark.
- Preserve smooth existing vanilla light values and practical cave visibility.
- Explore vanilla model face-shading and current 26.3 core terrain/block/entity shaders; avoid assuming that the old `Normal` vertex attribute exists on terrain.
- Prototype depth-based screen-space contact darkening / ambient occlusion **only if** `minecraft:main` depth reads work under the final 26.3 compositor.
- Never label this as real directional cast shadows: no guaranteed shadow maps, light-source occlusion or off-screen geometry.

### V8.2 — Inkline
- Explore depth-discontinuity silhouette outlines, complemented by carefully gated luminance/gradient edges.
- Thin neutral-dark contour by default; selective subtle light highlights when appropriate.
- Compare blocks, entities, foliage, transparent surfaces, particles, hand-held items and HUD.
- Depth and image edges cannot by themselves identify every same-depth block boundary or reliably separate entity IDs. Prefer fidelity over false edges.

### V8.3 — Chromaglow
- Separate *luminous surface recognition* from bloom scattering, instead of treating every white patch as a lamp.
- Explore ember-gold (torches, lanterns, lava), cool cyan (soul sources), violet (selected magical sources), and neutral-white accents.
- Investigate vanilla-safe emissive textures/material cues or stage-specific shader masks where technically possible; do not assume fragment postprocess knows the block type.
- Colored halos are an appearance effect. Real colored light cast on other blocks, with shadows, requires capabilities this pack has not established.

### V8.4 — Cloudcraft
- Research Minecraft 26.3 `minecraft:core/clouds.vsh` and `minecraft:core/clouds.fsh` (renamed in 26.3).
- Prototype soft edge gradient, underside shading, fluffy silhouettes, and day/night tint.
- Keep sky/white blocks separate from cloud masks: v7 infers clouds from bright nearly neutral pixels, which is not reliable.
- Test Fancy Clouds, transparency/OIT, OpenGL and Vulkan; recognize core overrides are officially unsupported and renderer-dependent.

### V8.5 — Skyflow
- Research sky-specific shader paths so treatment is not based on blue pixels alone.
- Art targets: softer horizon, warmer golden-hour gradient, subdued star/moon treatment, atmospheric dusk, weather continuity.
- No unintended tinting of blue blocks, water or UI.

### V8.6 — Toon Grade & Integration
- Restrained tonal banding and colorful but not over-saturated palette.
- Protect pixel-art textures, text legibility and dark-scene detail.
- Calibrate outline × ambient shadow × bloom × exposure interactions; avoid crushed blacks, glow halos, clipping and flicker.

## Technical feasibility gates

1. **Depth access:** prototype `use_depth_buffer: true` input from `minecraft:main` in `end_of_frame`; inspect data and handling after 26.3 OIT, with both graphics APIs. If unusable, redesign edge/AO implementation rather than promising full depth outlines.
2. **Core shader surface:** inspect exact 26.3 renderer shader source and compilation requirements. Core shaders are not an officially supported stable resource-pack API and can conflict with other renderers/packs.
3. **Lamp classification:** prove that specific emitter surfaces can be identified. RGB-only extraction is not material identification; use a conservative fallback if surface tagging is unavailable.
4. **Cloud integration:** verify final 26.3 renamed shader entry points and sky/transparency interactions.
5. **Validation:** compile, load, play and capture images in a real Minecraft 26.3 client. Static validation alone is insufficient.

## Delivery sequence (visual first, no optimization/ports work yet)

- **v8-pre.1 — Shape laboratory:** directional face tone and depth read proof-of-concept; capture shaded builds.
- **v8-pre.2 — Inkline laboratory:** world/entity contour passes and transparency/HUD behavior.
- **v8-pre.3 — Chromaglow laboratory:** light-source response by family; carefully controlled bloom.
- **v8-pre.4 — Cloudcraft + Skyflow:** own cloud silhouettes and sky treatments.
- **v8-pre.5 — Unified art pass:** tune combined look and visual defects; visual quality over speed, but never tolerate crashes.
- **v8 stable:** only after successful static validation, runtime compilation, matched screenshot review and no critical visual regressions.

**Testing scenes:** midday/overcast/night in a block-built village, dense forest, cave with torch and soul-light sources, night city, snow biome, sunset above clouds, rainy world, water coast, Nether lava/soul biome, End, and foliage/transparent/moving entity/HUD closeups. Compare Vanilla, v7 and each v8 candidate with matching scene, camera and settings.

## Known non-goals of v8
- True dynamic shadow maps, physically correct global illumination or colored light transport.
- Bundling or copying other projects' shaders, textures, code or assets.
- FPS-first simplification of the intended final image.
- Backporting or forward-porting to other Minecraft versions.

## Evidence and caution
- [Mojang: Minecraft Java Edition 26.3](https://www.minecraft.net/en-us/article/minecraft-java-edition-26-3): always-on `minecraft:end_of_frame`, new post effects, core shader changes, ShaderC changes and officially unsupported core override warning.
- Existing Minecraft post-effect definitions demonstrate `use_depth_buffer` in JSON, but do not guarantee that the final 26.3 main depth buffer is usable at our insertion point under every transparency/API configuration.
- Modrinth pages linked above are art references; do not infer their claimed performance or dependencies apply to NotVisuals.

## Decision policy
A feature is **candidate** until its renderer data and shader compilation are proven, **experimental** until gameplay screenshots and logs show it works, and **shippable** only after visual QA. If a core effect is technically inaccessible in vanilla 26.3, document the fallback honestly instead of inventing a result.
