# NotVisuals — third-party licenses and provenance

**Audit status: ongoing.** Check [the machine-readable rights status](docs/RIGHTS_STATUS.json) and run `python scripts/license_audit.py --release` before preparing an official ZIP. A file being available on GitHub or supplied by another person does **not** establish permission to relicense, redistribute, or publish it. This register records open issues, not assumed grants.

| Material | Source/evidence | Status and required action |
| --- | --- | --- |
| **Aurora Sky original atlas:** `source/aurora_sky/sun_atlas/part_*.b64`; generated `assets/minecraft/textures/environment/celestial/sun.png` | [Aurora Sky integration record](docs/V8_AURORA_SKY.md) confirms externally supplied atlas | **UNVERIFIED.** Confirm artist, origin, license or written permission and credit; not automatically CC BY-NC-SA |
| **Aurora Sky supplied core shaders:** applicable `assets/minecraft/shaders/core/{sky,clouds,position_tex,position_color,stars}.*` | [Aurora Sky integration record](docs/V8_AURORA_SKY.md) notes third-party shader provenance pending | **UNVERIFIED.** Identify original code authors and source; secure rights before GPL claims/release |
| **Minecraft renderer assets / Mojang material:** runtime `minecraft:*` includes and any copied game fragments | Game renderer API / external development references | **Not licensed by NotVisuals.** Preserve Mojang/Microsoft rights; avoid unpermitted redistribution of copied assets |
| **Experimental So Tuff, Fog and experimental shader reference ZIPs** | [Research notes](docs/V8_REFERENCE_RESEARCH.md): no licenses found and no literal copying reported | **Reference only.** Do not import content without license verification |
| **VanillaDI / vanilla-shaders** | Investigated as prospective references, not confirmed in this branch | **Not presumed imported or cleared.** If code is copied later, record upstream URL, commit, author, license and notices |
| **Historical `pack.png`** | Reused icon from v7, published during the repository's GPLv3-only period | **GPLv3 historical rights persist** for legitimate copies. Confirm original authorship before claiming any exclusive rights; do not represent it as CC-only |

For any new third-party material, document: **repository URL and immutable revision, file paths, authors, copyright, license name/text, attribution, modification/redistribution rights, and verification status**.

**Release gate:** unresolved Aurora Sky dependencies must be removed/replaced or supported by verifiable written/licensed redistribution rights before a public R20/Modrinth release. Experimental test ZIPs are not evidence that rights are settled.

See [LICENSING.md](LICENSING.md). This list may be updated as provenance is confirmed.
