# R20 — Visual stability and final polish (review-first)

**Current stage:** R20 scope agreed on 2026-11-08; no new graphics features, no FPS/VRAM optimization, no compatibility ports. The user likes the R19 aesthetic and wants to preserve it. The work is **audit → reproduce → small change → A/B → approve**, not feature development.

## Ground truth and source-sync condition

The exact owner-provided pack analyzed is `NotVisuals_26.3_v8_C3_R19_Final_Visual_Update_EXPERIMENTAL(3).zip` with SHA-256 **`5ff3880673ea5d2facdf2d577b7b80129a1b3e01562a40776ffe5e8808b1fd8f`**. Its archive has 724 entries, 41 GLSL source files, 41 automatic postprocessing passes, 53 Radiance marker textures, and three license/attribution files in `LICENSES/`. The ZIP passes archive integrity and JSON parsing checks. No runtime ShaderC or in-game approval is inferred.

**R19 source was pushed** in commit `39dd9b0`. Its first CI rejected CRLF→LF-normalized text; the R20 validation allows only this reversible normalization for unchanged historical files, and records five intentional shader edits in [R20_CHANGESET.json](R20_CHANGESET.json). The original R19 manifest and archive SHA-256 stay intact.

## Audit findings from the actual R19 package (not root-cause confirmations)

| Theme | What the source already does | Specific risk to investigate |
| --- | --- | --- |
| Radiance pink markers | 53 source marker PNGs; `radiance_seeds.fsh` reads exact RGBA8 IDs, `radiance_marker_clean.fsh` replaces recognized magenta IDs and adjacent one-pixel tinted fringes, **before** color/exposure and bloom passes | Antialiased/blended marker pixels may not match the ID or its 1-pixel fringe filter; do not change encoded IDs/palette without also changing matching shader decoders |
| Light flicker | `radiance_temporal.fsh` stabilizes intensity with depth and hue checks but has no camera motion vectors; `radiance_denoise.fsh` smooths light separately | Marker occlusion, camera motion, translucent particles, depth changes, competing nearby emitters or sudden exposure changes could still flicker |
| Outline | `depth_ink.fsh` (depth-based) is followed by `inkline.fsh` (local color-contrast based) in the 41-pass default chain | Combined darkening or outlines on leaves, glass, water, hand, HUD and fine texture; test both stages and leave the outline alone unless visibly excessive |
| Sun and moon bloom | `position_tex.fsh` includes a **directional celestial corona** and the later `highlight_extract.fsh` + four-scale `bloom_composite.fsh` add image-space bloom | Possible double halo, white clipping, moon overexposure, star blur, twilight pop, weather mismatch. Avoid global bloom reduction that dims ores and emissives |

**Important:** These are concrete paths and potential failure mechanisms, **not proof of the cause of the user's observed flickering or pink dots**. Fixes require real screenshots/short clips, because the static shader code cannot confirm render result on the user's GPU.

## Ordered R20 checks

### P0 — First address only visible defects

1. **Pink dots / marker leakage:** daylight + cave, 1 and 4 blocks away, front and diagonal, slow/fast camera motion, and 16:9/fullscreen. Check ore faces, glowstone, candles, lichen and shroomlight. If pink appears, report source block and whether visible with still camera vs in motion. Any fix must preserve marker decoding and all 53 color classes while leaving legitimate pink world pixels intact.
2. **Nether flicker:** glowstone wall, lava, soul fire, shroomlight and portal independently. Fixed camera for 20 seconds then slow 180° turn. Compare Vanilla, R19 (single pack), and previous accepted R18 if available. Classify flicker as **source block**, **localized light spill**, **bloom halo** or **whole-scene exposure**. Never infer the root cause from FPS alone.

### P1 — Visual finish, not new effects

3. **Outline:** compare unlit vs lit edges, foliage, fine ores, glass, water and HUD/held items in third person. Check for double contours, stair-stepping and flicker when moving. Preserve recognizable silhouettes and the chosen restrained ink style.
4. **Sun/moon bloom:** noon, dawn, dusk, moon phases, rain/storm and looking at sky near horizon/zenith. Check separate disc, halo, cloud transition and fine star contrast. Alter only the celestial-specific component if the globe-wide bloom is already good.
5. **Post-F3+T and dimensions:** ensure exposure history does not flash, shaders stay active, no reset ghosting or black frames; test transitions Overworld ↔ Nether ↔ End.

### P2 — Only if time and evidence

6. **Color consistency / material feel:** ore Radiance, amethyst, sculk, water lilies, waving leaves, fog and rain/snow. Do not take one attractive screenshot as proof of temporal stability; add 10-second clips for animated surfaces.

## Review process & acceptance

- Gather user screenshots **from the exact R19 ZIP**; if capturing flicker, a short clip is required (a still image cannot prove frame-to-frame instability).
- Record scene, world/dimension, graphics settings, active resource packs/mods, FOV, resolution and whether F3+T changes outcome.
- For each proposed edit: keep the original R19 snapshot, change the **fewest** shader/model lines, run static/R19 parity validation appropriate to a *derived* update (do not falsely require byte-identical R19 hashes after intentional edits), run applicable GPU shader checks where supported, then A/B visually in Minecraft.
- An intentional R20 change must create a new manifest/revision (do not overwrite the original R19 exact-hash manifest or retroactively rewrite the original 724 files' provenance). Commit changed files separately with credit and test notes.
- Reject any change that improves one screenshot but causes new light flicker, broken source-color classification, missing emissive blocks, clipping of celestial discs or false outlines.
- **No feature additions:** dynamic-light algorithms, voxel/global illumination, shadows, additional passes, material recognition, performance reductions, and other Minecraft versions are outside R20. Performance optimization can be explored in V9/V10 only upon explicit approval.
- Do not publish an installable ZIP on GitHub. Source remains in `src/pack/`; approved installable releases go to [Modrinth](https://modrinth.com/resourcepack/notvisuals). Respect GPL/CC/MIT redistribution rights.

## Acceptance table (manual results required)

| ID | Test | Status |
| --- | --- | --- |
| `NV-R20-01` | Pink marker leakage, still and moving camera | CODE PREPARED — MANUAL TEST PENDING |
| `NV-R20-02` | Nether emitter, localized light and exposure flicker | CODE PREPARED — MANUAL TEST PENDING |
| `NV-R20-03` | Depth Ink + Inkline against geometry/translucency/HUD | CODE PREPARED — MANUAL TEST PENDING |
| `NV-R20-04` | Sun halo and clipping at noon/sunrise/sunset/storm | CODE PREPARED — MANUAL TEST PENDING |
| `NV-R20-05` | Moon halo, phases, stars and twilight | CODE PREPARED — MANUAL TEST PENDING |
| `NV-R20-06` | F3+T, world/dimension transitions, window modes | NOT TESTED |
| `NV-R20-07` | Overall visual comparison with previous accepted R19 | NOT TESTED |

Do not mark any PASS merely from CI. Owner approval is required before a Modrinth release.
