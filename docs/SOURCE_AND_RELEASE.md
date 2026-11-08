# Source archive vs. official resource-pack download

**Modrinth:** https://modrinth.com/resourcepack/notvisuals is the official installation download location.

The public GitHub repository is organized as *source code* rather than a ready-to-use resource pack.

- `src/pack/pack.mcmeta`, `src/pack/pack.png`, `src/pack/assets/`: editable source of the resource pack.
- `scripts/`: reproducible build and validation.
- `docs/`: development and licensing.
- `dist/`: locally generated installation ZIP, excluded from Git.
- `source/`: auxiliary input/art source, where applicable.

GitHub's **Code → Download ZIP** output has no `pack.mcmeta` at the archive root. Minecraft will not load it as a resource pack. The builder extracts the correct contents from `src/pack/` and copies required notices into an installable ZIP.

CI validates internally but does not provide a resource-pack ZIP download link. Do not attach installable ZIPs to GitHub releases. Upload approved and tested ZIPs to Modrinth separately.

**No DRM:** since source is public and the project grants GPLv3 / CC BY-NC-SA / MIT rights file-by-file, third parties may legally rebuild or redistribute within those licenses' conditions. Modrinth is the preferred **official** channel, not an exclusive copyright restriction.

The stable `main` source still reflects v7; newer user-supplied full R19 source must be separately imported with its MIT third-party credit notices.
