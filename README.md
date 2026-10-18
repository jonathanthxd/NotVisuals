# NotVisuals

**Vanilla graphics, reimagined.**

NotVisuals is an experimental **Minecraft: Java Edition 26.3** resource pack that enhances the game's image through vanilla post-processing shaders. No Iris, OptiFine, or shader loader is required.

> **Development baseline:** v7, identical in visual content to the previously published build. Experimental v8 variants are intentionally **not** included in `main`.

[**Download on Modrinth**](https://modrinth.com/resourcepack/notvisuals) · [**Report a bug**](https://github.com/jonathanthxd/NotVisuals/issues) · [**Roadmap**](docs/ROADMAP.md)

## Features

- Automatic post-processing through `assets/minecraft/post_effect/end_of_frame.json`.
- Adaptive exposure, atmosphere and colour grading.
- Multi-pass bloom, adaptive pixel styling, vignette and finishing passes.
- Optional `pixel_vivid` and `soft_glow` effects, applied with commands.
- All shaders and post-effect definitions are editable source files.

NotVisuals applies **screen-space post-processing**. It is not a full shader loader and does not promise physically accurate global illumination, ray tracing or real geometric shadows.

## Install

1. Download the current release from [Modrinth](https://modrinth.com/resourcepack/notvisuals), or build the pack from this repository.
2. Put the generated `.zip` into `.minecraft/resourcepacks/` **without extracting it**.
3. Enable NotVisuals from Minecraft's resource-pack menu.
4. The automatic effect runs while the pack is active. The following optional effects can be added using in-game commands (with appropriate permissions):

```mcfunction
/posteffect add @s notvisuals:pixel_vivid
/posteffect add @s notvisuals:soft_glow
/posteffect clear @s
```

`/posteffect clear` removes command-added effects; it **does not disable** the automatic `end_of_frame` pipeline. Combining both optional effects with the automatic pipeline may amplify glow or soften details.

## Development

**The repository root is the resource-pack root.** There is no nested `NotVisuals/` folder or committed release ZIP.

```text
NotVisuals/
├── pack.mcmeta
├── pack.png
├── assets/
│   ├── minecraft/post_effect/end_of_frame.json
│   └── notvisuals/
│       ├── post_effect/{pixel_vivid,soft_glow}.json
│       └── shaders/post/*.fsh
├── scripts/
│   ├── validate_pack.py
│   └── build_pack.py
├── docs/
│   ├── ARCHITECTURE.md
│   └── ROADMAP.md
└── LICENSE
```

Requirements: Python **3.10+**, standard library only.

```bash
python scripts/validate_pack.py
python scripts/build_pack.py
```

The build script creates `dist/NotVisuals_26.3_v7.zip` with only the playable pack content. You can also use the editable repository directory directly in `.minecraft/resourcepacks/` for local testing, if supported by your Minecraft installation.

> Static validation checks resource layout, JSON parsing and shader references. It **cannot** prove that GLSL compiles or that the effects look correct inside Minecraft. Test actual builds in Minecraft 26.3 before publishing.

## Development priorities

1. **Visual fidelity first** — improve every viable artistic system until the main build reaches its target visual quality.
2. **Optimization second** — profile and reduce GPU/VRAM cost while preserving the approved look.
3. **Compatibility last** — investigate and implement ports only after the main build is visually complete and optimized.

See [the development roadmap](docs/ROADMAP.md) and [technical architecture](docs/ARCHITECTURE.md).

## License

This project is licensed under **GPL-3.0**. See [LICENSE](LICENSE) for the complete terms. Minecraft is a trademark of Mojang Studios / Microsoft; NotVisuals is an independent resource pack.
