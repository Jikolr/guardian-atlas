[← Visitor guide and project home](../README.md)

# Maintaining Guardian Atlas

A static Guardian Tales data and research explorer, compatible with GitHub Pages.

## Explore

- `dist/index.html`: 130 searchable datasets (the original five caches and 125 additional decoded tables), nested fields, sorting, filters, and pagination.
- `dist/research.html`: findings, extraction methods, validation evidence, and remaining uncertainties.
- XP calculator: hero/weapon variants, internal level indices, cumulative thresholds, and table download.
- Lua: all 6,344 recovered scripts, path/function search, category filters, function jumps, line numbers, file search, and downloads.
- Code: 36,384 types, their 293,384 methods and 253,660 fields; native addresses for the game assembly where available.
- Maps: references for 2,050 decoded maps and the unresolved test-map entry.
- Unity: object counts for all 4,267 archives and a compressed full object inventory.
- Events: 114 readable event definitions, including two normalized copies.
- Audit: every one of the 15,278 downloaded files, status filters, hashes, and downloadable catalogs.

Collections and source chunks are fetched only when opened. Original APK binaries, local preferences, and account data are not copied into the website. Metadata literals are not published wholesale. The existing five caches overlap with several static tables; their counts should not be added as unique gameplay entities.

## Preview

Serve `dist` over HTTP, for example `python -m http.server 8765 --directory dist`, then open http://localhost:8765/research.html. Opening HTML directly from the filesystem will not load JSON.

## Rebuild

With the sibling `guardian-analysis` outputs available, run `prepare_data.py` followed by `prepare_research.py`. The latter also reads the original event files from the source path defined in that script. No game is launched or script executed during extraction/building. The committed `dist` is self-contained and needs no build step on GitHub.

## Publish

The included GitHub Actions workflow publishes `dist` on a push to `main`. Repository Settings → Pages must use GitHub Actions. All asset URLs are relative, including the research page, so repository subpaths are supported.

## Interpretation

The XP calculator uses internal indices (0–219), not verified UI levels. It assumes no partial XP at the starting level. Stored caps and regional variants must be considered. Native formulas describe the APK's unpatched path; IFix/Lua corrections and server behavior can differ. The folder and APK package names differ, so exact region/version alignment is unverified.

Lua files are source text. The compiled-code browser is a metadata index, not a C# decompiler. The map viewer reconstructs stored placements and resolved static artwork; live scripted behavior and event rendering remain incomplete. Original files remain intact outside the website.

See the research overview and downloadable offline report for evidence and validation details.


## Visual library

Open `visual.html` for searchable graphic previews, heroes, monsters/bosses, items and maps. The highlighted XP/research link is available from the main table and visual library.

- 29,140 graphic objects cataloged; 29,078 previews available, including 7,813 individually cropped atlas icons. Previews are at most 768 pixels; animation atlases are labeled, not presented as assembled characters.
- Images matched to 700 hero, 5,147 monster, 2,524 NPC and 5,399 item records using asset-name fields. Andras is searchable by her established alias and `demon_slayer`. Other localized aliases are not guessed.
- 2,027 parsed maps with interactive layers, tile inspection, thumbnails and static artwork coverage. 24 additional map entries are explicitly unavailable (legacy formats or failed decryption).
- Meshes use stored rotations and original UVs/textures. Lighting, animated characters, particles and runtime changes are not recreated. Event markers are counted but not drawn. Structural mode covers unresolved tiles. Fit map focuses on floor tiles, excluding distant staging objects; those remain in the object selector.
- Map and mesh payloads are gzipped and require a browser with DecompressionStream support. The published folder is self-contained; no game installation is needed to browse it.

Extraction utilities are in the sibling `guardian-analysis` folder: `export_gallery.py`, `export_atlas_icons.py`, `export_maps.py`, `export_tilesets.py`, `link_visual_records.py`, and `finalize_visual_maps.py` (run last for coverage and thumbnails). These require the original local input files and UnityPy; they are not required for deployment.


## Search and downloads

- Record and graphic searches have a **Name only** option. Record name searches match `Name` and established display aliases, without checking unrelated nested fields.
- Related artwork links carry the record ID and use its matched asset IDs. Name searches landing on an empty section automatically try the other visual sections.
- Record inspectors, tables, graphic details and map viewers expose download actions.
- `files.html` browses original game content, decrypted/decoded files, unknown binaries and hosted exports separately. Original files remain unchanged. Local account settings, notifications, follower history and analytics are excluded.
- Hosted exports download directly. Original/recovered downloads use GitHub Release ZIPs. Visitors download the containing archive, open it in the file browser (locally, never uploaded), then save individual files. Each extracted file is checked against its SHA-256. Exact small subfolders can be repackaged as ZIP; large folders use archive parts. Large export folders can also be downloaded as browser-generated ZIP parts.
- The complete 3.55.0 snapshot uses `prepare_snapshot_release.py`, then `publish_snapshot_release.py`. The builder currently pins the reviewed 3.55.0 comparison run and new-version installation: update these inputs explicitly for a future patch; do not reuse them as an automatic latest-version detector.
- The builder validates every included source against the captured SHA-256 inventory, checks ZIP integrity, and writes independent ZIP parts plus coverage and checksum metadata into the sibling `guardian-release-archives/3.55.0` directory. Never commit these archives. It writes a pending catalog; live download links remain unchanged until publication succeeds.
- The publisher obtains an existing GitHub credential in memory, uploads to a draft release, verifies asset sizes and SHA-256 digests, then publishes tag `game-files-3.55.0-snapshot`. It switches the local website catalog only after all assets pass verification, preserving current website exports. Run `python sanitize_public_exports.py` afterward, then review and commit/push website changes with GitHub Desktop.
- This release contains 34 ZIPs, 16,011 original files and 9,432 decoded files. APK/runtime binaries, local account state and generated shader caches are excluded. Three files have no decoded output (ChinaMain.json, DragonTalon.json and short_story_clevatess_test.bytes); their originals are included. See release `coverage.json` for the exact scope. Historical 3.54.0 releases remain separate.


## Character directory and shared views

Run `python prepare_profiles.py` from the repository after rebuilding visual catalogs and data tables. It reads the sibling `guardian-analysis/decoded-static` data and current website exports, writes `dist/data/characters.json.gz` and `character-aliases.json`, and enriches the existing hero media links. Run it last because rebuilding visual catalogs otherwise replaces that enrichment.

Profiles group records by `OriginId`; default/exclusive weapon IDs and exact battle-style class/action references provide links. Names carry evidence labels. Biography matching uses a unique English opening sentence, not a recovered localization-key mapping. Keep these limitations visible when extending the mappings.

`atlas-tools.js` stores favorites and the comparison basket in the visitor's local browser. View settings live in URL parameters. There is no account or server database. The published game-file release archives are immutable snapshots and do not need rebuilding for these UI changes.

`name-evidence.json` holds manually reviewed biography-based inferences. Each entry records the source text ID and a supporting phrase; the builder verifies both the name and phrase against that text. These checks confirm the evidence exists, not that the inferred identity is proven. Keep this confidence category distinct from confirmed names. Dedicated profiles use `character.html?id=…`; legacy `characters.html?id=…` bookmarks redirect there.


## Native-code and evidence exports

`python prepare_native.py` exports all nonzero Scripts.dll method mappings to compressed chunks in `dist/data/research/native`. It uses the installed offline Capstone/ELF tools. Ranges end at the next mapped game entry point, are restricted to the executable section, and are capped at 64 KiB. Unconsumed or capped ranges are explicitly partial, not complete decompiled functions. This is a reproducible disassembly export, not automatic semantic analysis.

`python prepare_evidence.py` refreshes the evidence catalog, copied reports, all existing assembly excerpts, extraction scripts and audit summaries. The new page code uses gzip decompression for native chunks. The shared sidebar lives in `site-nav.js` / `site-nav.css` and is included by every HTML entry page.

Research metadata chunks under `data/research/code` are now `.json.gz` files. `prepare_research.py` writes that format directly; `prepare_evidence.py` can migrate old JSON chunks after verifying decompression preserves their exact bytes. Run the evidence exporter after the native exporter to refresh direct-download catalog entries. Original Release ZIPs remain unchanged.
