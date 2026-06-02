# Rails 8.1 Upgrade — Changes and Fixes

This document summarises the changes made on the `rails-8.1` branch to upgrade SEEK from Rails 7.2 to Rails 8.1.

---

## 1. Core Upgrade

**Rails 7.2.3.1 → 8.1.3** (`Gemfile`, `Gemfile.lock`)

The Gemfile was updated to `gem 'rails', '8.1.3'` and `bundle update rails` was run to pull in the new Rails 8.1.x dependency tree.

---

## 2. Deprecation Warnings Fixed

### 2.1 `resources` hash argument must be keyword-splatted (`config/routes.rb`)

Rails 8.2 deprecates passing a plain hash as the second argument to `resources`. The `has_dashboard` concern used:

```ruby
resources :stats, stats_options.reverse_merge(only: []) do
```

Fixed by keyword-splatting:

```ruby
resources :stats, **stats_options.reverse_merge(only: []) do
```

### 2.2 `ActiveSupport::Multibyte::Chars` / `String#mb_chars` (`lib/seek/grouped_pagination.rb`, `app/controllers/publications_controller.rb`, `test/unit/content_blob_test.rb`)

`mb_chars.unicode_normalize` is deprecated. Replaced with native `String#unicode_normalize` throughout. In `content_blob_test.rb`, a `.force_encoding('UTF-8')` call was also needed because the file was read in binary mode (`'rb'`), yielding an `ASCII-8BIT` string which raises `Encoding::CompatibilityError` on `unicode_normalize`.

### 2.3 `ActiveSupport::Configurable` — gem upgrades (`Gemfile.lock`)

Two gems triggered this warning:

- **`active_model_serializers`** 0.10.15 → 0.10.16: the old version included `ActiveSupport::Configurable` in a way that raised a deprecation on Rails 8.1.
- **`omniauth-rails_csrf_protection`** 1.0.2 → 2.0.1: the old version unconditionally included `ActiveSupport::Configurable`; 2.0.1 skips this on Rails 8.1+.

Both gems were upgraded via `bundle update`.

### 2.4 RSpec `fixture_path` (singular) deprecated (`spec/rails_helper.rb`)

Rails 7.1+ deprecated the singular `fixture_path` config in favour of `fixture_paths` (array). Fixed:

```ruby
# before
config.fixture_path = "#{::Rails.root}/spec/fixtures"
# after
config.fixture_paths = ["#{::Rails.root}/spec/fixtures"]
```

---

## 3. Test Failures Fixed

### 3.1 16× `ActionController::BadRequest: Invalid request parameters: EOFError` (`test/test_helper.rb`)

**Root cause:** Rack 2.2.x added strict `EOFError` handling in `handle_empty_content!` for multipart parsing. Rails' `ActionController::TestCase#scrub_env!` clears the request body and content-length between requests in the same test, but never cleared `CONTENT_TYPE`. After a multipart POST (file upload), subsequent GET requests in the same test inherited `Content-Type: multipart/form-data; boundary=...` with an empty body, causing Rack's parser to raise `EOFError`.

This affected 16 tests across `DataFilesControllerTest`, `ModelsControllerTest`, `SopsControllerTest`, `PresentationsControllerTest`, `DocumentsControllerTest`, and `CopasiTest`.

**Fix:** Monkey-patched `ActionController::TestCase::Behavior#scrub_env!` in `test/test_helper.rb` to also delete `CONTENT_TYPE`, so each request sets it fresh:

```ruby
module ActionController
  class TestCase
    module Behavior
      private
        def scrub_env!(env)
          env.delete_if { |k, _| k.start_with?("rack.request", "action_dispatch.request", "action_dispatch.rescue") }
          env["rack.input"] = StringIO.new
          env.delete "CONTENT_LENGTH"
          env.delete "RAW_POST_DATA"
          env.delete "CONTENT_TYPE"   # added
          env
        end
    end
  end
end
```

This bug is present in Rails 8.1.0 through 8.1.3 and has not been fixed upstream.

### 3.2 `DataFilesControllerTest#test_should_download_from_url` — `Enumerator#empty?` (`test/functional/data_files_controller_test.rb`)

**Root cause:** In Rails 8.1, `ActionDispatch::Response#body` returns the raw Rack stream object (an `Enumerator`) for `send_data` responses, rather than a joined `String` as in Rails 7. Calling `assert_not_empty @response.body` failed because `Enumerator` does not respond to `#empty?`.

**Fix:** Changed the assertion to collect and measure the streamed body, comparing its byte size against the mocked fixture file:

```ruby
assert_equal File.size("#{Rails.root}/test/fixtures/files/file_picture.png"),
             @response.body.to_a.join.bytesize
```

### 3.3 4× `SinglePagesControllerTest` — 302 instead of 200 — `caxlsx_rails` upgrade

**Root cause:** In Rails 7.2, `ActionView::Rendering#_normalize_options` set `options[:template] = action_name` before custom renderers ran. In Rails 8.1, this was refactored: template defaulting moved to `_process_render_template_options` inside `render_to_body`, which is called AFTER custom renderers. The `caxlsx_rails` xlsx renderer relied on `options[:template] == action_name` being true when it ran (to then substitute in the correct template name). In Rails 8.1 `options[:template]` is `nil` at that point, so the condition was false, the template was never set, and `render_to_string` fell back to looking for the action-name template in HTML format, raising a missing-template error caught by the rescue block which then redirected (302).

**Fix:** Upgraded `caxlsx_rails` 0.6.4 → 0.7.1, which explicitly handles `options[:template].nil?` before the condition check:

```ruby
if options[:template].nil?
  options[:template] ||= action_name
  options[:prefixes] ||= ...
end
options[:template] = filename.gsub(%r{^.*/}, '') if options[:template] == action_name
```

### 3.4 `EmtExtractorTest#test_handles_invalid_json_file` — JSON error message format (`test/unit/extended_metadatas/emt_extractor_test.rb`)

**Root cause:** The `json` gem (2.19.7) changed its error message format. The old format was position-based (`"784: unexpected token at ..."`); the new format is descriptive (`"expected object key, got EOF at line N column N"`). The test regex was hardcoded to the old format.

**Fix:** Replaced the hardcoded regex with a more general one matching the new format:

```ruby
assert_match /Failed to parse JSON file: .+ at line \d+ column \d+/, error.message
```

### 3.5 `IsaExporterComplianceTest#test_Files_SHOULD_be_encoded_using_UTF-8` (`test/integration/isa_exporter_compliance_test.rb`)

**Root cause / history:** The test had swapped `assert_equal` arguments (expected and actual were reversed). Additionally, `send_data` in Rails 8 correctly returns `ASCII-8BIT` binary encoding for file downloads, whereas Rails 7 preserved the source string's `UTF-8` encoding — so the test was accidentally passing in Rails 7.

**Fix:** Renamed the test and replaced the assertion to properly verify the content is valid UTF-8:

```ruby
test 'Files SHOULD contain valid UTF-8 content' do
  assert @response.body.force_encoding('UTF-8').valid_encoding?
end
```

### 3.6 `AttributionsTest#test_should_remove_attribution_on_update` — empty attributions array lost in params (`test/functional/attributions_test.rb`)

**Root cause:** The test passed `attributions: []` (a Ruby empty array) to the `put :update` action. Before the `scrub_env!` monkey-patch (fix 3.1), this accidentally worked: the preceding multipart POST left `CONTENT_TYPE: multipart/form-data` in the env; `assign_parameters` detected this unrecognised MIME type, fell through to its `else` branch, and registered a custom param parser that passed the raw Ruby hash to the controller — preserving the `[]`. After the monkey-patch deleted `CONTENT_TYPE`, `assign_parameters` defaulted to `application/x-www-form-urlencoded` and called `to_query` on the params; `{ attributions: [] }.to_query` produces `""`, so `params[:attributions]` became `nil`. `Relationship.set_attributions` has an explicit `unless attributions_from_params.nil?` guard (to avoid accidentally deleting all attributions on incomplete requests), so it silently skipped the deletion.

**Fix:** Changed the test to encode the empty array as a JSON string, consistent with how all other tests in the file pass attribution params and with how the browser actually sends them:

```ruby
# before
attributions: []
# after
attributions: ActiveSupport::JSON.encode([])
```

`"[]"` survives URL encoding (`attributions=%5B%5D`), decodes back to `"[]"`, and `set_attributions` correctly parses it via `ActiveSupport::JSON.decode`.

---

## 4. Outstanding / Known Issues

- The `scrub_env!` monkey-patch in `test/test_helper.rb` is a workaround for a confirmed Rails bug ([rails/rails#54582](https://github.com/rails/rails/issues/54582)) not yet fixed upstream as of 8.1.3. It should be reviewed and removed if/when Rails fixes `scrub_env!` to also clear `CONTENT_TYPE`.
