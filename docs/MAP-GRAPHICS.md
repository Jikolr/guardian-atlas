# Original artwork on maps

The map viewer keeps its three terrain views and adds **Game graphics**, an optional layer of recovered character poses and collectibles. It loads the compressed artwork index, the current map's placement records and only that map's images. Category switches, source layers, inactive placements, unresolved markers, picking and shareable URLs work together. In graphics-only mode, nonvisual camera and event targets stay hidden until Markers is enabled.

## Source mapping

`export_map_entities.py` reads the original map components omitted from the compact website map files. `CharacterPlaceholder` versions 1–11 retain the configuration name, character behavior type, direction, pose and visibility fields. Every component must be consumed completely. The exact configuration name joins the shared character-name namespace across NPC, monster and hero tables; a civilian stored in the monster table does not automatically become an enemy.

Asset references distinguish bundle, prefab and skin: `/bundle/path:prefab#skin`. Phone bundles take precedence over APK bundles. Unity's AssetBundle container and prefab transform hierarchy select the correct SkeletonAnimation component and SkeletonData reference. Skeleton filenames alone are insufficient: unrelated prefabs and elemental palettes can share the same binary filename.

`export_map_sprite_frames.py` extracts the original Spine inputs. `render_map_sprite_frames.cjs` renders a static original pose into a transparent PNG with its source scale and foot origin. An explicit asset-reference skin overrides the prefab's initial skin. Exact directional views are preferred; a prefab containing only one view can supply that view with an explicit note. Multiple possible views are never arbitrarily substituted. Missing clips use a labeled setup pose. Source maps, frame dimensions and provenance remain available for validation.

`export_map_collectibles.py` resolves purple coins from their stage/chapter configuration and original atlas. Star pieces use their original mesh/material assets. Acquired state, floating animation and quest conditions are not simulated. Ambiguous chapter mappings remain unresolved.

## Rebuild

Use an already decoded snapshot and a Python runtime with UnityPy, Pillow and NumPy. The frame-rendering helper also needs the existing Spine 3.8 WebGL runtime and Playwright with a Chromium browser. Supply local dependency paths explicitly; they are not included in public website data.

1. Run `export_map_entities.py --snapshot SNAPSHOT --phase prepare` to create `SNAPSHOT/map-graphics/sprite-jobs.json`.
2. Run `export_map_sprite_frames.py --snapshot SNAPSHOT --jobs SNAPSHOT/map-graphics/sprite-jobs.json --cache SNAPSHOT/map-graphics/rigs --library UNITYPY_LIBRARY`.
3. Run `render_map_sprite_frames.cjs --jobs SNAPSHOT/map-graphics/rigs/sprite-jobs-extracted.json --out dist/data/visual/map-entities --runtime SPINE_WEBGL_JS --playwright PLAYWRIGHT_MODULE --chrome CHROME_EXE` with Node.
4. Run `export_map_collectibles.py --snapshot SNAPSHOT --library UNITYPY_LIBRARY` with the same Python runtime, then `node render_map_collectibles.cjs --playwright PLAYWRIGHT_MODULE --chrome CHROME_EXE` to render the original star-piece mesh.
5. Run `export_map_entities.py --snapshot SNAPSHOT --phase finish`. This writes the compressed public artwork index and per-map data, with a plain index in the local build cache. Re-run this final step after changing frame exports.
6. Run `validate_map_entities.py --snapshot SNAPSHOT` and `test-map-graphics.cjs`. The browser test checks real maps, lazy loading, category/layer controls, collectible picking, shared links, mobile layout, failures and pixel-level scenery occlusion.

The original installation is read-only. Extracted skeleton caches stay in the snapshot workspace. Frame manifests, collectible placement intermediates, mesh inputs and the plain index live in the ignored `.build-cache/map-entities` directory. Exporters copy missing legacy intermediates from the previous public location automatically, so an existing capture can be rebuilt without re-extracting everything. Public output contains the compressed index, per-map placement files and rendered PNGs. Refresh the website download catalog after generating exports. The original-file Release archives do not need rebuilding for a viewer change.

## Limits

This is a static reconstruction, not a running game. Scripts can spawn, equip, move, recolor, rescale or hide characters after stage initialization. Conditional sprite overrides, many separately attached weapons, dynamic lighting and particles are not replayed. Match confidence, inactive placements and unavailable artwork are visible in the inspector instead of being silently replaced with generic pictures.
