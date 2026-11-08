# NotVisuals — licensing policy

This is the canonical **file-scoped license map** for NotVisuals. It is not a new standalone license. See the complete [GPLv3](LICENSE-CODE), the [CC BY-NC-SA 4.0 legal-code link](LICENSE-ASSETS.md), and the [third-party provenance register](THIRD_PARTY_LICENSES.md).

## Scope — only when the work is originally authored and rights are cleared

| Type/path | Applicable license | Notes |
| --- | --- | --- |
| `scripts/**/*.py`, original source tooling and `.github/workflows/**` | `GPL-3.0-only` | Programming and automation |
| Original `assets/**/*.fsh`, `assets/**/*.vsh`, `assets/**/*.glsl` | `GPL-3.0-only` | Shader source code; **exclude unverified third-party content** |
| Original shader/post-effect technical JSON, `pack.mcmeta`, configuration files, technical documentation | `GPL-3.0-only` | Unless another file-level notice applies |
| `pack.png` already present in the GPLv3-era v7 tree | `GPL-3.0-only` historical grant | Existing GPL rights cannot be withdrawn; the current policy does **not** make this icon CC-only |
| **New, independently original** images, textures, icons, graphics, audio, and other artistic media | `CC-BY-NC-SA-4.0` | Only if the respective rightsholder authorizes it; identify authors and scope before publishing |
| `source/**` containing encoded original artistic media | `CC-BY-NC-SA-4.0` | Encoded Base64 image remains artwork; **unverified imports excluded** |
| Third-party imports, Minecraft files or files with uncertain provenance | **No automatic project license** | Follow actual source terms / obtain permission |

An extension, location under `assets/minecraft/`, or the presence of a public GitHub file **never** establishes that NotVisuals owns it. Specific file notices and [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) supersede defaults.

## Unresolved Aurora Sky rights — v8 candidate

The work on `feat/v8-ink-and-light` integrates externally supplied resources whose rights have **not** been confirmed:

- `source/aurora_sky/sun_atlas/part_*.b64`, plus generated `assets/minecraft/textures/environment/celestial/sun.png`: third-party-supplied original sky atlas.
- Relevant `assets/minecraft/shaders/core/{sky,clouds,position_tex,position_color,stars}.*` integration files: original authorship/permissions must be checked before assigning new GPL rights.

**These items are not automatically relicensed GPLv3 or CC BY-NC-SA 4.0 by the project.** Neither possession of the files nor local testing proves redistribution rights. They must be **cleared or replaced** before an official Modrinth release. See [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md) and [Aurora Sky notes](docs/V8_AURORA_SKY.md). Research references are not granted licenses merely by being discussed.

## Rights and limitations

- GPLv3-covered software can be studied, modified, redistributed **and used commercially** subject to GPL obligations, including source/notice requirements on redistribution.
- Original CC BY-NC-SA 4.0 artwork can be shared and adapted **noncommercially**, with credit, license link, changes indication and ShareAlike obligations. Consult the full legal code for the meaning of NonCommercial.
- Third-party components preserve their actual licenses and notices. Some combinations may require additional GPL/CC compatibility analysis: co-packaging different files does not automatically make a new single dual-licensed work or authorize incompatible derivative combinations.
- The CC NonCommercial clause **cannot be imposed on GPLv3 code**. The complete resource pack is not OSI-open-source, although its original source code is open-source.
- Playing Minecraft with a pack is different from reusing artwork in a separate commercial product.

## Historical GPL license remains valid

The initial repository provided the unmodified GNU GPLv3 text as its sole `LICENSE` and described the project as GPL-3.0. **Already granted GPL rights are not retroactively withdrawn** from eligible copies of previously published versions, including content previously licensed as part of them. A change in the project's future distribution policy cannot cancel such rights. **The unchanged original v7 `pack.png` remains available under its earlier GPL grant to legitimate recipients; it must not be advertised as exclusively noncommercial.** New, separately identifiable artwork may use CC BY-NC-SA only with authorization from all its relevant authors.

Where older GPL content is incorporated into a later version, the earlier GPL terms remain applicable to that content. Copyright ownership and original authorship need separate verification; a historical license declaration is not proof the project had rights to third-party content.

## Contributions and commercial exceptions

Contributors retain their copyrights. Contributions must be licensed as documented in [CONTRIBUTING.md](CONTRIBUTING.md), with authorship and external material identified. No copyright assignment or permission for unrelated commercial exploitation is presumed. A special commercial license for CC artwork needs permission from every relevant owner.

## Official brand and distribution

See [TRADEMARKS.md](TRADEMARKS.md) for official-name and endorsement policy. Mandatory credit and lawful descriptive uses remain permitted.

The maintained [rights manifest](docs/RIGHTS_STATUS.json) and `scripts/license_audit.py` provide a **mechanical pre-release gate**. Development builds may still include experimental material, but official release builds must run `python scripts/build_pack.py --release`. That command refuses to proceed while known third-party rights are pending; a passing check is not a legal opinion or proof of permission. The current v8 Aurora Sky candidate is **not cleared**.

For Modrinth, use a custom/mixed/other license option (if offered) with **license URL**:

https://github.com/jonathanthxd/NotVisuals/blob/main/LICENSING.md

Display: **"GPL-3.0-only original code; CC BY-NC-SA 4.0 cleared original art; third-party works retain their own rights."** Do not label the entire resource pack exclusively GPL or CC. The generated ZIP should include `LICENSE`, `LICENSE-CODE`, `LICENSE-ASSETS.md`, `LICENSING.md`, `THIRD_PARTY_LICENSES.md` and `TRADEMARKS.md`. See [Modrinth metadata guide](docs/MODRINTH_LICENSING.md).

NotVisuals is independent and not affiliated with Mojang Studios / Microsoft. This scope document does not replace specialist legal review.
