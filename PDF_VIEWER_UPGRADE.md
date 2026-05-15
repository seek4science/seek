# PDF Viewer Upgrade: PDF.js v0.7.55 → v2.16.105

Fixes [#2343](https://github.com/seek4science/seek/issues/2343).

## What changed

### JavaScript (`vendor/assets/javascripts/pdfjs/`)

- **`pdf.js`** — upgraded from v0.7.55 (2012) to v2.16.105
- **`pdf.worker.js`** — added; v2 offloads PDF parsing to a Web Worker; its URL is passed at runtime via `PDFViewerApplicationOptions.set('workerSrc', ...)`
- **`viewer.js`** — added; replaces `viewer.js.erb` with the upstream v2 viewer application bundle
- **Removed:** `compatibility.js`, `debugger.js`, `l10n.js`, `viewer.js.erb` — no longer part of the pdfjs-dist package

### CSS (`vendor/assets/stylesheets/pdfjs/`)

- **`viewer.css.erb`** — replaced with the v2 stylesheet; `url(images/...)` references rewritten to use Sprockets `asset_path` helpers so images resolve correctly through the asset pipeline; `url(images/FILE)` in the upstream CSS becomes `url("<%= asset_path('pdfjs/FILE') %>")` — the `images/` segment is dropped because Sprockets serves `vendor/assets/images/pdfjs/FILE` as `pdfjs/FILE`

### Images (`vendor/assets/images/pdfjs/`)

- All PNG toolbar icons replaced with SVG equivalents from the v2 distribution
- New SVGs added for annotation types, secondary toolbar actions, layers, and tree items
- Removed obsolete PNGs (RTL variants, textures, loading spinner)

### View (`app/views/content_blobs/view_pdf_content.html.erb`)

- Rewritten to match the v2 viewer HTML structure
- JavaScript interaction updated from the old global `PDFJS` / `DEFAULT_URL` API to the v2 `PDFViewerApplicationOptions` API:

  ```js
  // Old (v1)
  DEFAULT_URL = '<%= @pdf_url %>'

  // New (v2)
  PDFViewerApplicationOptions.set('workerSrc', '<%= asset_path("pdfjs/pdf.worker.js") %>');
  PDFViewerApplicationOptions.set('defaultUrl', '<%= @pdf_url %>');
  PDFViewerApplicationOptions.set('disablePreferences', true);
  ```

- An inline empty L10n dictionary is embedded in a `<script type="application/l10n">` tag so `webL10n.setLanguage()` resolves immediately without needing locale resource files. Without this, `GenericL10n._ready` hung and blocked `PDFViewerApplication.initialize()`, causing a blank viewer.

### Asset pipeline (`config/initializers/assets.rb`)

- Removed precompile entries for the deleted files (`pdfjs/compatibility`, `pdfjs/debugger`, `pdfjs/l10n`)
- Added `pdfjs/pdf.worker` so the worker file is fingerprinted and served correctly in production

## Why v3+ is harder to upgrade to

PDF.js v3 (released late 2022) dropped its UMD/CommonJS builds and moved entirely to **native ES modules**. Every file in `pdfjs-dist` v3+ — `pdf.js`, `pdf.worker.js`, and the viewer — uses `import`/`export` syntax and, in the case of the viewer, `<script type="module">`.

This is incompatible with Sprockets, which concatenates and fingerprints JavaScript files but has no understanding of ES module semantics. Sprockets cannot resolve `import` statements, tree-shake, or correctly bundle a module graph, so simply dropping the v3 files into `vendor/assets/javascripts/` would produce a broken page.

To upgrade to v3+ the project would need one of:

- **A JavaScript bundler** (esbuild, webpack via `shakapacker`) wired into the asset pipeline to compile the ES module graph into a Sprockets-compatible bundle before it is served.
- **Import maps** (`importmap-rails`), which let the browser resolve bare ES module specifiers natively. This requires Rails 7+ and means serving `pdf.js` and `pdf.worker.js` directly from the browser's module loader rather than through Sprockets concatenation — a significant change to how assets are structured.
- **A CDN-pinned approach**, loading pdfjs from a CDN `<script type="module">` tag and abandoning the vendored-asset model entirely.

The v3 distribution does retain a `legacy/` directory with builds transpiled to ES5, but the viewer application itself still uses ES module imports internally and does not ship a self-contained legacy viewer bundle comparable to v2's `web/viewer.js`. Adapting that into a single Sprockets-servable file would require running it through a bundler manually for each upgrade.

In summary: upgrading to v3+ is not a drop-in vendor file swap — it requires a decision about the project's JavaScript build infrastructure first.

### Rake task (`lib/tasks/pdfjs.rake`)

Added `rake pdfjs:install` to reproduce the vendor update in future:

```sh
rake pdfjs:install
```

It downloads the pdfjs-dist zip from GitHub, copies `pdf.js`, `pdf.worker.js`, and `viewer.js` into `vendor/assets/javascripts/pdfjs/`, rewrites the CSS image URLs for Sprockets, and copies the SVG images.

### Tests (`test/functional/content_blobs_controller_test.rb`)

Updated assertion to match the new `defaultUrl` option:

```ruby
# Old
assert @response.body.include?("DEFAULT_URL = '#{download_path}'")

# New
assert @response.body.include?("PDFViewerApplicationOptions.set('defaultUrl', '#{download_path}')")
```
