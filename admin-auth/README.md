# Guardian Atlas admin setup

The editor is at `/guardian-explorer/admin/`. It has no public navigation link.
GitHub authenticates the owner; the hidden URL is not a security boundary.
The Worker accepts only Jikolr and verifies write access to Jikolr/guardian-atlas.

## One-time activation

1. Deploy `worker.mjs` as the Cloudflare Worker `guardian-atlas-auth` (Workers & Pages).
2. Set the ordinary variables from `wrangler.toml` in the Worker settings.
3. In GitHub Settings → Developer settings → OAuth Apps, register Guardian Atlas Editor.
   Homepage: `https://jikolr.github.io/guardian-atlas/admin/`.
   Callback: `https://YOUR-WORKER.workers.dev/callback`.
4. Put the OAuth Client ID and Client Secret into Cloudflare encrypted secrets named
   `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET`. Never put them in this repository or chat.
5. Set `authBaseUrl` in `dist/admin/settings.json` to the Worker URL (no trailing slash).
   Set `authReady` to true only after configuring both Worker secrets.
6. Commit/push the prepared site changes to main, then wait for Pages to finish.
7. Open the hosted admin URL and approve the GitHub login. Test with a draft before publishing.

GitHub OAuth's `public_repo` permission covers the user's public repositories, not
only this repository. The editor is configured for this repository and the Worker
restricts the login, but this does not narrow the underlying token scope. GitHub
shows the permission on first authorization; approve it only after reviewing it.
This setup assumes a PUBLIC repository. Do not expand to `repo` without review.
GitHub Pages workflows triggered by the CMS use the normal user OAuth token.

The OAuth state uses a short-lived Secure/HttpOnly cookie. Callback messages are
sent only to the configured exact site origin. Never add a wildcard origin.
The GitHub token is delivered to Decap in the browser, as required by its backend.
Leave GitHub's token expiration enabled; log in again when the token expires.
No analytics or unrelated scripts are loaded in the admin page. Log out on shared PCs.

## Content and builds

Edit `newsletter/posts/*.json` through the CMS. The body is Markdown; legacy HTML
and `newsletter/posts.json` are historical migration inputs, no longer authoritative.
`build_newsletter.py` renders pages and the archive. Existing article URLs are preserved.
Dependencies: `python -m pip install -r requirements-newsletter.txt`.
Build: `python build_newsletter.py`.
GitHub Actions runs this automatically before deploying `dist`.
Editorial workflow stores drafts on branches; a public repository's drafts are public.
The published boolean controls whether a merged article is included on the website.
No scheduler is configured: the date is a display date, not an embargo.

Local migration only: `migrate_newsletter.py` requires markdownify==1.2.0 and runs once.
The checked-in Decap CMS bundle is npm `decap-cms@3.16.3`, MIT license.

## Validation

`node admin-auth/test-worker.mjs` runs mocked OAuth success/denial tests, no credentials.
These tests do not replace a real login test after Cloudflare/GitHub configuration.
Do not claim authentication is live before testing the hosted callback.
