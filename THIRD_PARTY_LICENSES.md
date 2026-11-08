# NotVisuals — third-party licenses and provenance

**Audit status: ongoing.** Check [the machine-readable rights status](docs/RIGHTS_STATUS.json) and run `python scripts/license_audit.py --release` before preparing an official ZIP. A file being available on GitHub or supplied by another person does **not** establish permission to relicense, redistribute, or publish it. This register records open issues, not assumed grants.

| Material | Source/evidence | Status and required action |
| --- | --- | --- |
| **Aurora Sky original atlas:** source Base64 chunks and generated `sun.png` | [Private consent record](docs/AURORA_SKY_PERMISSION.md) | **CC BY-NC-SA 4.0** for original art by `masteirdixy`; self-declared, conveyed by owner 2026-11-08; credit in [CREDITS.md](CREDITS.md) |
| **Aurora Sky shader code:** artist-authored originals integrated into `assets/minecraft/shaders/core/*` | [Private consent record](docs/AURORA_SKY_PERMISSION.md) | **GPLv3** for portions authored by `masteirdixy`; integrated code and runtime includes may have other authors; original attachments not independently matched |
| **Minecraft renderer assets / Mojang material:** runtime `minecraft:*` includes and any copied game fragments | Game renderer API / external development references | **Not licensed by NotVisuals.** Preserve Mojang/Microsoft rights; avoid unpermitted redistribution of copied assets |
| **Experimental So Tuff, Fog and experimental shader reference ZIPs** | [Research notes](docs/V8_REFERENCE_RESEARCH.md): no licenses found and no literal copying reported | **Reference only.** Do not import content without license verification |
| **VanillaDI / vanilla-shaders** | Investigated as prospective references, not confirmed in this branch | **Not presumed imported or cleared.** If code is copied later, record upstream URL, commit, author, license and notices |
| **Animated Ore / Vanilla Emissive** (R19 supplied ZIP) | gitq © 2024; [upstream](https://modrinth.com/resourcepack/animated-ore) | MIT; retain original `LICENSES/ANIMATED_ORE_MIT.txt` and `LICENSES/R18_ATTRIBUTION.md`. Not automatically CC BY-NC-SA. |
| **Water Lilies!** (R19 supplied ZIP) | JustVoden / Just_Voden; [upstream](https://modrinth.com/resourcepack/water-lilies) | MIT; retain `LICENSES/WATER_LILIES_MIT.txt` and source attribution. Not automatically CC BY-NC-SA. |
| **Historical `pack.png`** | Reused icon from v7, published during the repository's GPLv3-only period | **GPLv3 historical rights persist** for legitimate copies. Confirm original authorship before claiming any exclusive rights; do not represent it as CC-only |

For any new third-party material, document: **repository URL and immutable revision, file paths, authors, copyright, license name/text, attribution, modification/redistribution rights, and verification status**.

**Release gate:** express consent for the artist's own materials was reported by the project owner. Independently owned code/assets still require their own rights. Technical R19 QA and the actual R19 ZIP are separate outstanding checks.

See [LICENSING.md](LICENSING.md). This list may be updated as provenance is confirmed.
