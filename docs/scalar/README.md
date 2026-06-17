# Scalar API Reference

An interactive [Scalar](https://github.com/scalar/scalar) reference for the
xCloud Public API surface that the five agent skills (`xcloud:servers`,
`xcloud:sites`, `xcloud:wordpress`, `xcloud:ssl`, `xcloud:account`) operate on.
Operations are grouped by skill so you can see exactly what each one can do,
the scope it needs, and what every request takes.

## Files

| File | Role |
|---|---|
| `skills-catalog.json` | **Source of truth.** One entry per skill, each listing its operations (method, path, params, body, scope). Hand-edited. |
| `build.mjs` | Generator. Transforms the catalog into a valid OpenAPI 3.1 document. |
| `xcloud-skills.openapi.json` | **Generated** OpenAPI 3.1 doc. Do not edit by hand. |
| `index.html` | Scalar page that renders `xcloud-skills.openapi.json`. |

## View it locally

The page fetches the spec with `fetch()`, so a `file://` double-click is blocked
by the browser. Serve the folder over HTTP instead:

```bash
# from the repo root — any static server works
npx serve docs/scalar
# or
python3 -m http.server -d docs/scalar 8080
```

Then open the printed URL (e.g. <http://localhost:8080>).

## Regenerate after changing the skills

1. Edit `skills-catalog.json` (add/remove operations, fix params, etc.).
2. Rebuild:
   ```bash
   node docs/scalar/build.mjs
   ```
3. Commit both the catalog and the regenerated `xcloud-skills.openapi.json`.

The build prints a summary (skills · tags · paths · operations) so you can sanity
-check the counts.

## Host on GitHub Pages

`index.html` and `xcloud-skills.openapi.json` are fully static — no build step at
serve time. Two common options:

- **Pages from `/docs`:** In repo **Settings → Pages**, set the source to the
  `main` branch `/docs` folder. The reference is then served at
  `https://<org>.github.io/<repo>/scalar/`.
- **Dedicated workflow / `gh-pages` branch:** copy `docs/scalar/*` to the site
  root in your Pages workflow.

> Keep the spec next to `index.html`; the page loads it with the relative path
> `./xcloud-skills.openapi.json`.

## Notes

- The reference is **documentation**, not a second source of truth for the API —
  the catalog is generated from the skills' own `SKILL.md` endpoint tables. If
  the skills change, update `skills-catalog.json` and rebuild.
- Scalar is loaded from the jsDelivr CDN. To pin a version, change the
  `@scalar/api-reference` script `src` in `index.html` to an explicit version.
