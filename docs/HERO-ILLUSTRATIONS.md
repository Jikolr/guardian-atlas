# Hero illustrations

`Explore → Hero illustrations` opens `dist/hero-illustrations.html`. It lists
captured original hero illustrations, including Myth forms, ascensions and
super costumes. Downloads are native-resolution transparent PNGs; small WebP
files are previews only. Separate character and effects files share a canvas
and pose so they line up when composited.
Only fully transparent outer margins are trimmed, using the union of all layers
plus padding. Distant particles and every visible source pixel are retained;
the original canvas and shared crop are recorded in the catalogue.

## Source and coverage

The 3.57.0 capture has 262 illustration bundles (259 downloaded bundles and
three APK-only bundles). Exact `PortraitAssetName` and costume `IllustAssetName`
references link the artwork to captured hero records. All 183 playable hero
origins with portrait references are covered. Additional artwork with no exact
table reference retains its source identifier rather than an invented name.
These are the illustrations present in this Korean capture, not a promise to
include artwork exclusive to another release or region.

`export_hero_illustrations.py` resolves the prefab's original Spine skeleton,
atlas and Texture2D pages through Unity object references. Background prefabs
are separate and are not rendered. The pipeline never executes the game code,
generates replacement artwork, or removes backgrounds by image segmentation.
Original bundles and extraction caches remain outside this repository.

## Transparency

The source atlases contain premultiplied RGB. Some RGBA4444 texels have color
at zero alpha; these invalid values are clamped during rendering. This prevents
ghost edges in a compositing preview without cropping the character's hair or
fine details.

Flames and glows may have opaque black texture pixels because the game uses
additive blending. The renderer derives their export alpha from emitted RGB,
retains the original mesh, clipping, draw order and colors, and writes a valid
RGBA PNG. PNG cannot encode an additive operation against an unknown future
background, so luminous effects are necessarily a portable alpha approximation.
No black rectangle is retained as an opaque background.

The original Spine 3.8 runtime also contains a signed UTF-8 byte bug affecting
six Korean attachment names. `prepare_hero_spine_runtime.cjs` creates a patched
local copy, preserves the license, and records the original and patched hashes.
It leaves the original runtime unchanged.

## Rebuild

Use a Python environment with UnityPy and Pillow and a Node environment with
Playwright plus Chrome/Edge. Supply local paths explicitly; no captured data or
runtime path is embedded in the website.

1. Run `export_hero_illustrations.py --snapshot <capture> --version <game-version> --output <work>`.
2. Run `prepare_hero_spine_runtime.cjs` to prepare a local runtime copy; see its
   argument help at the top of the file.
3. Run `render_hero_illustrations.cjs --work <work> --runtime <patched-runtime>
   --playwright <module-path> --chrome <browser-path>`.
4. Run `build_hero_illustration_gallery.py --work <work> --download-base <release-download-url>`.
   Use the planned public release URL. It validates alpha and
   SHA-256 hashes, re-encodes lossless PNGs, verifies decoded pixel equality,
   generates previews, and builds ZIP packs below the release asset size limit.
5. Run `serve_hero_gallery.py --work <work>` for local preview and downloads.
   This server maps download URLs to the prepared local assets without changing
   the saved catalogue.
6. Run `publish_hero_illustrations.py --release-dir <work>/release` to validate
   the prepared release. Add `--publish` only when publishing is authorized.
7. Verify that the saved catalogue's download base matches the published release.
   Refresh the site's export file catalogue too. Never deploy a catalogue whose
   release assets have not been published and verified.

Full PNGs and ZIPs belong on Releases, not in `dist`: GitHub Pages has a 1 GB
published-site limit. The publisher stages a draft, verifies every asset, then
publishes. It refuses to overwrite an asset with different contents.

Run `test-hero-illustrations.cjs` for gallery filters, pagination, deep links,
PNG download/alpha integrity, preview failures, keyboard use and narrow layouts.
The build's `gallery-validation.json` records the output dimensions, alpha
ranges, source hashes and framebuffer checks for every exported PNG.
