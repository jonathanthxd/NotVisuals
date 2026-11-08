# NotVisuals R19 — Final Visual Update (experimental)

Base: R18. Target: Minecraft Java **26.3**, pack format 97.1. Public release planned for R20 after real in-game verification.

## Priority 1: Radiance on ores
- 90 ore and ore-family models now attach a small exact-palette Radiance marker via inheritable block templates. Original R18 textures, `_e` animations, and their metadata are unchanged.
- Added new marker classes **42–53** (12 categories): diamond, emerald, redstone, lapis, gold, copper, iron, quartz, ancient debris, coal, amethyst and sculk catalyst.
- The marker classification now supports a third palette row for class 53 (RGB 227,76,25), and the alpha-encoded JFA seed field already supports 8-bit class IDs. Target seed resolution remains 512×288.
- Each new class has a **short, weak halo** (3.2–4.2 blocks). Coal/debris/sculk are intentionally very subtle. Lights of classes 1–41 unchanged.
- The user's existing R14 temporal stabilization, clustering and noise rejection remain unchanged; there can still be screen-space occlusion and aliasing in Minecraft.
- Gems receive small locally-isolated boost in existing Chromaglow extraction; no extra postprocess pass.

## Priority 2: Celestial Depth
- The End night stars now sample **3D direction mapped to cube faces**, avoiding equirectangular polar convergence at zenith. Aurora curtains and galaxies remain.
- Overworld night gets restrained 3D starlight and a distant cool dust patch, fading fully by day; existing night atlas and solar/lunar bloom unchanged.
- Sky artifacts may still appear near cube face boundaries; guards reduce the chance of half-stars.

## Priority 3: Atmosphere Weather Edition
- New **original** 64×256 RGBA rain and snow textures at the vanilla 26.3 precipitation paths. Softer streaks and snowfall; no added loader or mod.
- The existing weather response and sky light remain intact. Lightning volumetrics and accurate rain fog would require dimension/weather signals not available in this pipeline.

## Priority 4: Material Soul
- Amethyst clusters and buds gain an emissive crystal surface (light_emission 11) and nearby faint violet Radiance (class 52).
- Sculk catalyst gets a restrained turquoise ambient source (class 53).
- Sulfur cave vanilla fog color is gently tempered toward yellow-green when a matching distinctive greenish fog input is detected; this is heuristic, not exact biome ID.
- **20 pointed-dripstone and sulfur-spike variants** get very sparse, original satin micro-highlights at the centerline of their existing cross models. No RGB light emission, no new physical lighting and no altered source rock textures. Keeps their natural cave silhouette.

## No changes to
- **41 preexisting Radiance sources**, color profiles, and JFA/history/temporal parameters for them.
- Damage amber, water lilies, armor trims, original Animated Ore files, End fog/stars/auroras other than targeted updates, Nether features and foliage/fluid waving.
- Depth Ink is still on by default; post graph stays at **41 passes**, with no additional framebuffer targets.

## Limits & required in-game QA
- Experimental core shaders are **not supported as a stable Mojang resource-pack API**.
- Runtime visuals require user test on Minecraft Java 26.3. Static checks and GPU synthetic checks do not establish F3+T or FPS success.
- Prior tests of old releases expecting exact old inventory remain deliberately unchanged, except updated current preflight expectation if present.
- Monitor pink marker artifacts on ores, occlusion flicker near adjacent mineral blocks, and unusual bright spots in inventories. In deep caves, compare FPS near 20+ emissive ores with R18.
- Credit and licenses from `LICENSES/` of R18 preserved. Newly written shaders/models and precipitation sprites are NotVisuals-original.
