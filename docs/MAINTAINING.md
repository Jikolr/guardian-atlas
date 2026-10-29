[← Visitor guide and project home](../README.md)

# Maintaining Guardian Atlas

A static Guardian Tales data and research explorer, compatible with GitHub Pages.

## Explore

- `dist/index.html`: 130 searchable datasets (the original five caches and 125 additional decoded tables), nested fields, sorting, filters, and pagination.
- `dist/research.html`: findings, extraction methods, validation evidence, and remaining uncertainties.
- XP calculator: hero/weapon variants, internal level indices, cumulative thresholds, and table download.
- Lua: all 7,153 recovered scripts, path/function search, category filters, function jumps, line numbers, file search, and downloads.
- Historical 3.54.0 code browser: 36,384 types, their 293,384 methods and 253,660 fields; native addresses for the game assembly where available.
- Maps: 2,054 complete decoded payloads, including three APK maps; 2,031 interactive parsed maps, 23 unsupported legacy formats and one incomplete test-map entry.
- Unity: object counts for 4,402 phone/APK bundles. The older full object-inventory download is explicitly historical.
- Events: 114 readable event definitions, including two normalized copies.
- Historical 3.54.0 audit: every one of the 15,278 downloaded files, status filters, hashes, and downloadable catalogs.

Collections and source chunks are fetched only when opened. Original APK binaries, local preferences, and account data are not copied into the website. Metadata literals are not published wholesale. The existing five caches overlap with several static tables; their counts should not be added as unique gameplay entities.

## Preview

Serve `dist` over HTTP, for example `python -m http.server 8765 --directory dist`, then open http://localhost:8765/research.html. Opening HTML directly from the filesystem will not load JSON.

## Rebuild

The committed `dist` is self-contained. For a new already decoded capture, use `import_snapshot.py` rather than the historical builders:

```powershell
python import_snapshot.py --work "<snapshot-workspace>" --source "<phone-dump>" --version 3.57.0
```

The workspace must contain `phone/decoded/files`, `phone/tables` (validated JSON and record indexes for the five `k1ng` tables), and optionally `apk/decoded/com.kakaogames.gdtskr/assets`. The phone dump is read-only. Decoding tools, keys and complete originals stay outside this repository. Install UnityPy, Pillow and NumPy in the selected Python runtime, or pass a dependency folder with `--library`.

The importer captures a baseline under `<snapshot-workspace>/website-import`, compares original hashes with the existing archive catalog, imports tables and Lua, merges additional APK content, refreshes changed images/maps/tilesets, then rebuilds profiles and Orbital Lift exports. It preserves existing Lua IDs and website-generated table IDs across reordered JSON sections and named records. Primitive scales retain their index identity. Cache record IDs remain the IDs supplied by the current game; they are distinct from website-generated IDs. Downloaded game content takes precedence over duplicate APK paths. Biography IDs are remapped only when the exact earlier text is still present. Existing reviewed name decisions are reapplied.

Phases can be resumed with `--phase data|scripts|events|visuals|maps|tilesets|links|finish`. Run `links` after data and visual changes, and `finish` last. The last phase losslessly compresses research map-reference JSON and records the update summary. `prepare_snapshot_release.py` handles archive packs separately; see the download section below. Refresh export entries in both live and pending catalogs after all data writes.

`prepare_data.py`, `prepare_research.py`, `prepare_native.py` and `import_update.py` retain the earlier investigation pipeline and hard-coded historical inputs. They must not be run against the current snapshot without adapting their inputs and preserving existing IDs. No game is launched or game script executed during importing.

## Publish

The included GitHub Actions workflow publishes `dist` on a push to `main`. Repository Settings → Pages must use GitHub Actions. All asset URLs are relative, including the research page, so repository subpaths are supported.

## Interpretation

The XP calculator uses internal indices (0–219), not verified UI levels. It assumes no partial XP at the starting level. Stored caps and regional variants must be considered. Native formulas describe the APK's unpatched path; IFix/Lua corrections and server behavior can differ. The current phone dump and APK both identify com.kakaogames.gdtskr version 3.57.0. Older native research used a different capture and remains labeled 3.54.0 evidence.

Lua files are source text. The compiled-code browser is a metadata index, not a C# decompiler. The map viewer reconstructs stored placements and resolved static artwork; live scripted behavior and event rendering remain incomplete. Original files remain intact outside the website.

See the research overview and downloadable offline report for evidence and validation details.


## Visual library

Open `visual.html` for searchable graphic previews, heroes, monsters/bosses, items and maps. The highlighted XP/research link is available from the main table and visual library.

- 30,758 graphic objects cataloged; 30,684 previews available, including individually cropped atlas icons. Previews are at most 768 pixels; animation atlases are labeled, not presented as assembled characters.
- Images matched to 700 hero, 5,147 monster, 2,524 NPC and 5,399 item records using asset-name fields. Andras is searchable by her established alias and `demon_slayer`. Other localized aliases are not guessed.
- 2,031 parsed maps with interactive layers, tile inspection, thumbnails and static artwork coverage. 24 additional map entries are explicitly unavailable (legacy formats or failed decryption).
- Meshes use stored rotations and original UVs/textures. Lighting, animated characters, particles and runtime changes are not recreated. Event markers are counted but not drawn. Structural mode covers unresolved tiles. Fit map focuses on floor tiles, excluding distant staging objects; those remain in the object selector.
- Map and mesh payloads are gzipped and require a browser with DecompressionStream support. The published folder is self-contained; no game installation is needed to browse it.

Extraction utilities are in the sibling `guardian-analysis` folder: `export_gallery.py`, `export_atlas_icons.py`, `export_maps.py`, `export_tilesets.py`, `link_visual_records.py`, and `finalize_visual_maps.py` (run last for coverage and thumbnails). These require the original local input files and UnityPy; they are not required for deployment.


## Search and downloads

- Record and graphic searches have a **Name only** option. Record name searches match `Name` and established display aliases, without checking unrelated nested fields.
- Related artwork links carry the record ID and use its matched asset IDs. Name searches landing on an empty section automatically try the other visual sections.
- Record inspectors, tables, graphic details and map viewers expose download actions.
- `files.html` browses original game content, decrypted/decoded files, unknown binaries and hosted exports separately. Original files remain unchanged. Local account settings, notifications, follower history and analytics are excluded.
- Hosted exports download directly. Original/recovered downloads use GitHub Release ZIPs. Visitors download the containing archive, open it in the file browser (locally, never uploaded), then save individual files. Each extracted file is checked against its SHA-256. Exact small subfolders can be repackaged as ZIP; large folders use archive parts. Large export folders can also be downloaded as browser-generated ZIP parts.
- `prepare_snapshot_release.py` now accepts an explicit version, snapshot directory, phone source and archive destination. The snapshot must contain `phone/reports/inventory.json`, `phone/decoded`, `phone/tables`, and the APK extraction plus `apk/decoded-inventory.json`. Example: `python prepare_snapshot_release.py --version 3.57.0 --snapshot-root SNAPSHOT --phone-source PHONE_DUMP --output SNAPSHOT/packs`. Paths are local arguments, never embedded in public catalogs. The historical `prepare_file_downloads.py` is a 3.54.0 builder and must not be used for current snapshots.
- Archives remain outside this repository. The builder compares captured source SHA-256 values, uses independent stored ZIP parts of at most 250 MiB of file data, then verifies every ZIP's CRC, archive hash and every member's byte offset/hash used by the browser. It writes `file-catalog.pending.json`, `coverage.json`, `release-manifest.json`, `SHA256SUMS.txt` and `RELEASE.md`. The live catalog remains unchanged. After rebuilding website exports, repeat the same builder command with `--refresh-exports`; add `--refresh-live-exports` to refresh direct website downloads while preserving the live release and archive references. Use `--verify-only` to recheck archives.
- The published 3.57.0 release contains 45 ZIPs totaling 4,924,617,549 bytes: 16,383 original files (16,109 phone files and 274 APK assets) and 9,353 decoded outputs (9,350 phone outputs and three APK maps). APK resources use a separate `apk/` prefix. Hotfix content, decoded manifests and structured cache JSON are included. Player-specific minimap state, account data, runtime executables, metadata and extraction tools are excluded from public archives and remain in the local investigation. Already-readable events are included once as originals. The incomplete `short_story_clevatess_test.bytes` original is included; its partial decoded prefix is not presented as a complete map. `ChinaMain.json` and `DragonTalon.json` retain their original nonstandard JSON syntax.
- Publication is a separate action. `python publish_snapshot_release.py --version 3.57.0 --archives SNAPSHOT/packs` performs only local verification. Add `--publish` when publication is requested. If Git Credential Manager has no credential, `--desktop-account ACCOUNT` can use that explicit existing GitHub Desktop account through its installed credential provider. Credentials stay in memory and are never logged. The publisher uploads to a draft, verifies every asset, publishes `game-files-3.57.0-snapshot`, and only then activates the new local file catalog. Failed uploads do not mark local artifacts published. Historical releases remain separate. Run `python sanitize_public_exports.py` afterward before deploying the website.
- Test local downloads with an HTTP preview on port 8766 and `node test-snapshot-downloads.cjs --catalog SNAPSHOT/packs/file-catalog.pending.json --archives-dir SNAPSHOT/packs`. Set `PLAYWRIGHT_MODULE` if Playwright is outside the default module path. This checks individual file extraction and an exact folder ZIP against their expected SHA-256 values without uploading anything.


## Character directory and shared views

Run `python prepare_profiles.py` from the repository after rebuilding visual catalogs and data tables, with `ATLAS_STATIC_SOURCE` pointing to the current decoded static JSON folder. It reads that folder and current website exports, writes `dist/data/characters.json.gz` and `character-aliases.json`, and enriches the existing hero media links. Run it last because rebuilding visual catalogs otherwise replaces that enrichment.

Profiles group records by `OriginId`; default/exclusive weapon IDs and exact battle-style class/action references provide links. Names carry evidence labels. Biography matching uses a unique English opening sentence, not a recovered localization-key mapping. Keep these limitations visible when extending the mappings.

`atlas-tools.js` stores favorites and the comparison basket in the visitor's local browser. View settings live in URL parameters. There is no account or server database. The published game-file release archives are immutable snapshots and do not need rebuilding for these UI changes.

`name-evidence.json` holds manually reviewed biography-based inferences. Each entry records the source text ID and a supporting phrase; the builder verifies both the name and phrase against that text. These checks confirm the evidence exists, not that the inferred identity is proven. Keep this confidence category distinct from confirmed names. Dedicated profiles use `character.html?id=…`; legacy `characters.html?id=…` bookmarks redirect there.


## Native-code and evidence exports

`python prepare_native.py` exports all nonzero Scripts.dll method mappings to compressed chunks in `dist/data/research/native`. It uses the installed offline Capstone/ELF tools. Ranges end at the next mapped game entry point, are restricted to the executable section, and are capped at 64 KiB. Unconsumed or capped ranges are explicitly partial, not complete decompiled functions. This is a reproducible disassembly export, not automatic semantic analysis.

`python prepare_evidence.py` refreshes the evidence catalog, copied reports, all existing assembly excerpts, extraction scripts and audit summaries. The new page code uses gzip decompression for native chunks. The shared sidebar lives in `site-nav.js` / `site-nav.css` and is included by every HTML entry page.

Research metadata chunks under `data/research/code` are now `.json.gz` files. `prepare_research.py` writes that format directly; `prepare_evidence.py` can migrate old JSON chunks after verifying decompression preserves their exact bytes. Run the evidence exporter after the native exporter to refresh direct-download catalog entries. Original Release ZIPs remain unchanged.


## Current metadata alongside historical native research

The original compiled-code browser retains its 3.54.0 type/method IDs and disassembly links. Current 3.57.0 types, methods, fields and validated native-address indexes are exported separately under `dist/data/research/metadata-3.57.0/`. These indexes are structural evidence; they do not automatically revalidate the historical behavior reports. String literals, extraction keys, executables and local account settings are excluded from these website exports.
