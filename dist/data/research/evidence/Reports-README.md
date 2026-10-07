> Update 2026-09-18: the encrypted scripts, static tables and hidden IL2CPP metadata have now been decoded. The earlier limitations below are historical. See RAPPORT-HORS-LIGNE.md and audit/file-review-status.csv for the current findings.

# Guardian Tales: offline inspection findings

Original files were read only. Extracted material and analysis outputs are stored in this folder.

## Sources and version caveat

- Downloaded data: `com.kakaogames.gdtskr`
- XAPK: `Guardian+Tales_3.54.0_APKPure.xapk`
- XAPK manifest: version 3.54.0, version code 423, package `com.kakaogames.gdts`, ARM64 split.
- The data folder name ends in `gdtskr`; the APK package ends in `gdts`. Region/version equivalence is NOT established. Cache contents may also predate the downloaded source tables. Do not treat cross-source matches as proof of identical versions.

## What is available now

The data folder contains 15,278 files totaling 4,369,756,961 bytes (4.37 GB decimal). AssetBundles account for 4.01 GB; they have not been deleted or classified as exclusively graphics.

| Material | Count | Result |
|---|---:|---|
| Cached hero records | 701 | Exported to `decoded/heroes-bin.json` |
| Cached battle-action records | 2,670 | Exported to `decoded/battleactions-bin.json` |
| Cached monster records | 10,157 | Exported to `decoded/monsters-bin.json` |
| Cached NPC records | 4,073 | Exported to `decoded/npc-bin.json` |
| Cached English text records | 170,387 | Exported to `decoded/strings-bin-enUS.json` |
| Plaintext event JSON files | 114 | Readable in the original `files/events` directory |
| Plaintext Lua files in XAPK | 9 | Extracted under `apk/com.kakaogames.gdts/assets/GameScript` |
| Encrypted script resources | 6,344 | Not decrypted |

These are record counts, not counts of unique playable characters or distinct enemy types.

The five cache exports contain 187,988 records in total. The caches were decompressed, not decrypted. Their corresponding files in `files/static_data` remain opaque and were not decoded by this process.

Each table also has an `.index.json` companion. Its `record_position` links to the same position in the main JSON array. This preserves IDs for records, such as battle actions, whose JSON payload does not contain its own ID. The 64-bit index field is preserved as a decimal string to avoid JavaScript precision loss; its meaning is not established.

## Cache format recovered

Observed format: `k1ng` signature; little-endian 32-bit version, record count, and chunk count; 16-byte record index entries; 16-bit chunk sizes; padding to a four-byte boundary; compressed chunks.

Each chunk contains an LZ4 block followed by a four-byte little-endian decompressed length. Decoded chunks concatenate into records whose lengths are stored in the index. Gameplay records are JSON objects; localization records are UTF-8 strings.

Validation: all five files were fully consumed; every chunk's decoded length matched its trailer; every record boundary matched the indexed length; all gameplay records parsed as JSON; payload IDs matched index IDs wherever present; all localization records decoded as UTF-8. The unknown 64-bit index fields were not validated as checksums. Details and source SHA-256 hashes are in `decoded/validation.json`.

The decoder follows the [official LZ4 block specification](https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md). The surrounding `k1ng` container layout was inferred from these files and validated against their contents.

## Actual code that can be studied

`apk/com.kakaogames.gdts/assets/GameScript/Battle/BattleAction/ManualKnightBattleAction.lua` is readable source with comments. At line 647, `action_state_class:apply_damage` constructs a damage record, sets sender/target/modifier, sets stun duration to 0.4, selects effects, applies knockback conditions, and publishes the damage command. The stinger attack applies knockback only on its first hit.

`apk/com.kakaogames.gdts/assets/GameScript/base/battle_init.lua` is about 271 KB of readable Lua. It exposes battle helpers and interfaces to `CS.Oak` C# code. At line 2249, an attack-modifier helper delegates calculation to `CS.Oak.IBattleActionExtensions.CalculateAttackModifierFromDps`. Consequently, this Lua file does not itself reveal every combat formula.

The original `files/events/FortuneTeller.json` contains readable scene sequences: character lookup, dialogue codes, movement, animation, camera changes, sounds, and waits. These are scripted behavior definitions, not merely graphics.

The ARM64 split contains `libil2cpp.so` (170,204,904 bytes), `libxlua.so`, and `liblz4.so`; those were extracted. No file named `global-metadata.dat` was found in the XAPK inventory. Its absence under that name does not establish that metadata is absent entirely. Compiled functions and the script decryption routine have not yet been reconstructed.

## Original encrypted sample

The supplied 112-byte sample exactly matches `files/GameScript/DemonWorldDataStore.encrypted` by SHA-256:

`0d9737d2d16c8c8e522c66da8c5ddab76c8a3311dfa897fd9a08f852540ed4ae`

There are related resources at `files/GameScript/eventcontrollers/DemonWorldDataStore.encrypted` (1,024 bytes) and `files/GameScript/sections/DemonWorldDataStore/DemonWorldDataStoreSection1.encrypted` (512 bytes). This context points toward a script resource rather than the earlier filename-only guess of a saved-state record.

All 6,344 encrypted scripts have lengths divisible by 16. Their first blocks repeat extensively: one first block occurs in 3,616 files; the original sample's first block occurs in 310. This is useful evidence of shared structure or deterministic processing, but it does not establish AES, ECB/CBC mode, or a key. No encryption key has been recovered and the original sample remains undecrypted.

## Next useful investigation

Trace a specific mechanic through the readable Lua and recovered tables. For encrypted scripts, identify the loader and cryptographic routine in the compiled client, accounting for the package/version mismatch. A running emulator is not required for those static steps; runtime inspection may become useful if metadata or keys are unpacked only during execution.
