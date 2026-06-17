# Scalar landing page

A [Scalar](https://github.com/scalar/scalar) **guide / landing page** for the
xCloud agent skills (`xcloud:servers`, `xcloud:sites`, `xcloud:wordpress`,
`xcloud:ssl`, `xcloud:account`). It explains what the skills are, how to install
them in Claude Code, and shows example requests.

This page intentionally contains **no API endpoints** — it links out to the full
[xCloud API](https://app.xcloud.host/api/v1/docs) for the endpoint reference.

## Files

| File | Role |
|---|---|
| `build.mjs` | Generator. Produces the OpenAPI 3.1 document (intro/description only, empty `paths`). Edit the intro copy here. |
| `xcloud-skills.openapi.json` | **Generated** doc. Do not edit by hand. |
| `index.html` | Scalar page that renders `xcloud-skills.openapi.json`. |

## View it locally

The page fetches the spec with `fetch()`, so a `file://` double-click is blocked
by the browser. Serve the folder over HTTP instead:

```bash
# any static server works
npx serve docs/scalar
# or
python3 -m http.server -d docs/scalar 8080
```

Then open the printed URL (e.g. <http://localhost:8080>).

## Regenerate after editing the copy

1. Edit the `INFO_DESCRIPTION` (and links) in `build.mjs`.
2. Rebuild:
   ```bash
   node docs/scalar/build.mjs
   ```
3. Commit the regenerated `xcloud-skills.openapi.json`.

## Served by the xCloud app

The xCloud app serves this page at **`/agent/skills`** (see the xCloud repo,
`routes/web.php` → `agent.skills.docs`). The blade route rewrites the
`app.xcloud.host` host to the request host, so the **xCloud API** link resolves
to the same deployment (e.g. `xcloud.test/api/v1/docs` locally). Re-copy
`xcloud-skills.openapi.json` into the xCloud repo (`docs/agent/`) after
regenerating.

## Host on GitHub Pages

`index.html` and `xcloud-skills.openapi.json` are fully static. In repo
**Settings → Pages**, set the source to the `main` branch `/docs` folder; the
page is then served at `https://<org>.github.io/<repo>/scalar/`.

> Keep the spec next to `index.html`; the page loads it with the relative path
> `./xcloud-skills.openapi.json`.

## Notes

- Scalar is loaded from the jsDelivr CDN. To pin a version, change the
  `@scalar/api-reference` script `src` in `index.html` to an explicit version.
