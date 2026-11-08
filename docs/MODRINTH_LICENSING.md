# Modrinth license disclosure for NotVisuals

**NotVisuals is mixed-licensed, not globally GPL or globally CC.**

If Modrinth exposes a **Custom / Other / Mixed** license choice, use it with the link:

https://github.com/jonathanthxd/NotVisuals/blob/main/LICENSING.md

If the current interface does not support this, explain the license split prominently in the description instead of selecting a misleading single-license label; request platform guidance if necessary.

## Suggested description text

> **Licensing:** Original NotVisuals shader/tooling code is GPL-3.0-only, while original artistic assets with confirmed rights are CC BY-NC-SA 4.0. Third-party material retains its actual license, and Aurora Sky original artwork and code are credited to masteirdixy based on privately reported author consent; final R19 QA and source audit remain pending. [Full licensing and provenance](https://github.com/jonathanthxd/NotVisuals/blob/main/LICENSING.md). The whole distribution is not OSI-open-source.

## Release gate

- [x] Record masteirdixy's reported express consent (2026-11-08) for original CC BY-NC-SA art and GPLv3 shader code.
- [ ] Review the actual full R19 package for additional third-party assets and correct license credits.
- [ ] Verify each redistributed file's attribution and applicable license.
- [ ] Use `python scripts/build_pack.py --release`, not the experimental developer build; pending third-party rights must block this command.
- [ ] Include license and notices in ZIP.
- [ ] Check Modrinth metadata does not label the whole pack GPL or CC.
- [ ] Run CI, test the pack in Minecraft and inspect the finished ZIP.

See [THIRD_PARTY_LICENSES.md](../THIRD_PARTY_LICENSES.md).

The existing v7 `pack.png` was previously offered with GPLv3; the new NC license does **not** withdraw those historical rights. CC BY-NC-SA applies only to newly identified art whose authors can grant it.
