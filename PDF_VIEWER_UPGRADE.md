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
