# Modrinth license disclosure for NotVisuals

**NotVisuals is mixed-licensed, not globally GPL or globally CC.**

If Modrinth exposes a **Custom / Other / Mixed** license choice, use it with the link:

https://github.com/jonathanthxd/NotVisuals/blob/main/LICENSING.md

If the current interface does not support this, explain the license split prominently in the description instead of selecting a misleading single-license label; request platform guidance if necessary.

## Suggested description text

> **Licensing:** Original NotVisuals shader/tooling code is GPL-3.0-only, while original artistic assets with confirmed rights are CC BY-NC-SA 4.0. Third-party material retains its actual license, and the original Aurora Sky art and code have author-reported consent from masteirdixy, while the actual R19 release still requires technical acceptance. [Full licensing and provenance](https://github.com/jonathanthxd/NotVisuals/blob/main/LICENSING.md). The whole distribution is not OSI-open-source.

## Release gate

- [x] Record masteirdixy's express author-reported licensing consent for original Aurora Sky artwork and shader code (2026-11-08).
- [ ] Review the actual R19 ZIP for additional third-party content and retain the original consent privately.
- [ ] Verify each redistributed file's attribution and applicable license.
- [ ] Use `python scripts/build_pack.py --release`, not the experimental developer build; pending third-party rights must block this command.
- [ ] Include license and notices in ZIP.
- [ ] Check Modrinth metadata does not label the whole pack GPL or CC.
- [ ] Run CI, test the pack in Minecraft and inspect the finished ZIP.

See [THIRD_PARTY_LICENSES.md](../THIRD_PARTY_LICENSES.md).

The existing v7 `pack.png` was previously offered with GPLv3; the new NC license does **not** withdraw those historical rights. CC BY-NC-SA applies only to newly identified art whose authors can grant it.
