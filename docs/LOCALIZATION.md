# Website languages

The public site offers English, Spanish, French, Japanese, Korean, Simplified Chinese, Traditional Chinese and Indonesian. The top-right selector remembers the visitor's choice in local storage. A `?lang=fr` (or another supported locale tag) link selects a language explicitly. English is the default.

Translations are hosted with the site. No page content or browsing information is sent to a translation service. Only the selected language's compressed pack is downloaded; English needs no pack.

## What is translated

Navigation, interface text, search/filter controls, explanatory website copy, accessibility labels and the currently published newsletter articles are translated. Dynamically inserted interface text uses the same catalog. Form values, recovered game records, raw game dialogue, Lua/code blocks, file identifiers and downloadable game files retain their source content. Proper names and technical terms may remain in their original form. The private Decap editorial interface is separate from the visitor language selector.

## Editing articles

Continue editing English articles normally in `/admin/`. Each translation in `newsletter/translations/<locale>/<slug>.json` contains `title`, `summary`, the complete Markdown `body`, and a `sourceSha256`. The hash covers the English title, summary and body. Changing those fields makes existing translations stale: the next build keeps the updated English article available and shows a translated notice until its translations are revised. Changes to publication state, date, category or cover do not invalidate article prose. Newly published articles initially use the same English fallback.

Keep evidence URLs, image URLs and inline code unchanged. Keep the same second-level sections in the same order; the builder preserves their original anchor IDs for existing links. After revising a translation, set its `sourceSha256` using `build_i18n.source_hash(original_post)`. Never update the hash without reviewing the translated content against the edited source.

## Updating interface translations

`i18n/source.json` maps stable English messages to IDs and source locations. `i18n/manual-source.json` supplements it with runtime labels the source extractor cannot reliably detect. `i18n/locales/<locale>.json` maps those IDs to translations. Numbered placeholders such as `{0}` can move to match the language's grammar, but every placeholder must remain present.

The source extractor is a maintenance aid, not part of deployment. Install its development parser with `npm install --prefix .i18n-tools --no-package-lock --no-save acorn@8.15.0`, then run `python extract_i18n_sources.py`. Review the extracted inventory and update all seven catalogs together. The extractor also writes numbered chunks under `i18n/source-chunks/` for translation work. Source code, selectors and identifiers detected by the extractor should be kept verbatim. Prefer complete interface messages with numbered placeholders for newly added dynamic text.

The runtime translates text and display attributes while keeping DOM elements, handlers, option values and source data intact. Add `data-game-source`, `translate="no"` or `data-i18n-ignore` to any newly introduced raw-content region. Do not use visible button text as application state; use data attributes or stable values.

## Build and verification

Run `python build_newsletter.py` followed by `python build_i18n.py`. The Pages workflow runs both automatically. Packs are deterministic gzip files in `dist/data/i18n/`, with a content-hashed manifest for cache invalidation. The compiler rejects missing interface messages, changed placeholders, altered article evidence links and altered source code.

Run `python test_i18n_build.py` for editorial integrity and stale-content checks. Run `node test-i18n.cjs` with Playwright available (or set `PLAYWRIGHT_MODULE` to its installed module path) for real-page language, interaction, persistence, source-preservation, mobile and network-failure checks. The browser suite starts its own local static server and uses Edge by default; `PLAYWRIGHT_CHANNEL` overrides that choice.
