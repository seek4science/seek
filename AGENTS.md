# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## About FAIRDOM-SEEK

FAIRDOM-SEEK (v1.18) is a Rails 7.2 / Ruby 3.3 web platform for sharing scientific research data, models, simulations, and workflows. It implements the ISA (Investigation–Study–Assay) data model extended for life science research. Public instance: [FAIRDOMHub](https://fairdomhub.org/).

## Commands

### Development

```bash
bundle exec rails server          # Start the app (default: port 3000)
bundle exec bin/jobs               # Start Solid Queue background workers
```

### Testing

```bash
# Run all tests (as CI does)
bundle exec rails test test/unit
bundle exec rails test test/functional
bundle exec rails test test/integration
bundle exec rspec spec

# Run a single test file
bundle exec rails test test/unit/data_file_test.rb

# Run a single test by name
bundle exec rails test test/unit/data_file_test.rb -n test_some_method

# Run a single RSpec file
bundle exec rspec spec/models/some_spec.rb
```

### Database

```bash
bundle exec rake db:setup          # Create and seed DB
bundle exec rake db:schema:load    # Load schema (faster than running migrations)
bundle exec rake db:migrate
bundle exec rake seek:upgrade      # Post-migration data upgrades
```

### Search / Solr

```bash
script/start-docker-solr.sh           # Start Solr via Docker
script/stop-docker-solr.sh            # Stop Solr via Docker
bundle exec rake seek:reindex_all     # Rebuild Solr index
```

### Redis (cache + sessions)

```bash
script/start-docker-redis.sh          # Start Redis via Docker (seek-redis on :6379)
script/stop-docker-redis.sh           # Stop Redis (keeps the seek-redis-data-volume)
script/reset-docker-redis.sh          # Wipe and restart Redis (clears cache AND sessions)
script/delete-docker-redis.sh         # Remove the stopped container and its data volume
```

`REDIS_MAXMEMORY` (default `256mb`) sets the `maxmemory` limit. For `docker-compose.yml` it is read
from `docker/redis.env`; for the scripts and the other compose variants it is a host env var. Redis
backs both `Rails.cache` and sessions on one instance (`allkeys-lru`).

### Linting

```bash
bundle exec rubocop                # Uses .rubocop.yml — max line length 120, no frozen string literals required
```

### Assets

```bash
bundle exec rake assets:precompile
```

## Architecture

### ISA Data Model

The core hierarchy is **Investigation → Study → Assay**, with assets (DataFile, Sop, Model, Workflow, etc.) linked to Assays. `Investigation`, `Study`, `Assay`, and `ObservationUnit` use `acts_as_isa` (`lib/seek/acts_as_isa.rb`). All downloadable research assets (DataFile, Sop, Model, Presentation, Document, etc.) use `acts_as_asset` (`lib/seek/acts_as_asset.rb`).

### Authorization

Two-layer system in `lib/seek/permissions/`:

- **PolicyBasedAuthorization** — policy records stored in the `policies` table define access (view/download/edit/manage/delete). After create/update, an `auth_lookup` table per type is updated asynchronously via `AuthLookupUpdateJob` for performance.
- **CodeBasedAuthorization** — additional state-based checks (`state_allows_#{action}?`) can block actions even when policy permits (e.g. an Assay with linked samples can't be deleted).

All models call `acts_as_authorized` which includes both layers. Check `can_#{action}?(user)` on any resource instance.

### ApplicationRecord inclusions

`app/models/application_record.rb` mixes in nearly all cross-cutting concerns, so every model automatically gets: filtering (`HasFilters`), versioning (`Seek::VersionedResource`, `Seek::ExplicitVersioning`, `Git::Versioning`), authorization (`Seek::Permissions::ActsAsAuthorized`), tagging, favourites, discussions, extended metadata, DOI support, RO-Crate snapshots, Zenodo deposits, and feature-flag gating (`feature_enabled?`).

### Feature Flags

`Seek::Config.<feature>_enabled` controls whether each resource type is active. `ApplicationRecord.feature_enabled?` derives the flag name from the class name (e.g. `DataFile` → `Seek::Config.data_files_enabled`). Controllers call the generated `data_files_enabled?` before_action. The full list of flaggable features is in `lib/seek/enabled_features_filter.rb`.

### Configuration

Runtime configuration is stored in the database and accessed via `Seek::Config` (`lib/seek/config.rb`). Settings are defined in `lib/seek/config_setting_attributes.yml`. All settings are cached per-request in `RequestStore` and in Rails cache. Use `Seek::Config.setting_name` to read; settings are set via the Admin UI or `Seek::Config.setting_name = value`.

### Standard Controller Pattern

Most asset controllers include `Seek::AssetsCommon` and use `Seek::AssetsStandardControllerActions` (`lib/seek/assets_standard_controller_actions.rb`) for standard CRUD. Controllers use `before_action :find_and_authorize_requested_item` for authorization checks. `api_actions :index, :show, :create, :update, :destroy` enables JSON API responses.

### JSON API

The REST API uses `active_model_serializers` with `BaseSerializer` (`app/serializers/base_serializer.rb`). Serializers inherit from `SimpleBaseSerializer` and expose a `policy` attribute and associated items. API integration tests live in `test/integration/api/` and use `ReadApiTestSuite` / `WriteApiTestSuite` mixins with FactoryBot factories named `min_<resource>` and `max_<resource>`.

### Background Jobs

All async work uses `Solid Queue` (`solid_queue` gem, tables in the primary database). Jobs are in `app/jobs/`. Worker/dispatcher/scheduler processes are started via `bin/jobs` (see `config/queue.yml` for topology, `config/recurring.yml` for scheduled jobs); `script/run_solid_queue.sh` wraps this with automatic restart-on-exit for deployment. Key jobs: `AuthLookupUpdateJob`, `ReindexingJob`, subscription email jobs, RDF generation. (Migrated from `delayed_job` - the `delayed_job_active_record` gem and its tables remain installed as a rollback safety net for now.)

### Semantic / RDF

Models including `Seek::Rdf::RdfGeneration` (`lib/seek/rdf/`) auto-generate RDF on commit. Models including `Seek::BioSchema::Support` expose `to_schema_ld` (Schema.org / Bioschemas JSON-LD). SPARQL queries over a Virtuoso triple store are configured in `config/virtuoso_settings.yml`.

### Search

Full-text search via Sunspot/Solr. `Seek::Config.solr_enabled` gates search queries. Reindexers in `app/reindexers/` handle background reindexing after model changes.

### Testing Conventions

- Test framework: **Minitest** (`test/`) for unit, functional (controller), and integration tests; **RSpec** (`spec/`) for a smaller set of model/service specs.
- `test/test_helper.rb` includes `AuthenticatedTestHelper` — use `login_as(person_or_user)` to set the session user in controller tests.
- Factories are in `test/factories/` (split by type) and `test/factories.rb`. FactoryBot `create` calls wrap in `disable_authorization_checks` automatically.
- `disable_authorization_checks { ... }` disables policy checks in a block; useful in tests when you want to bypass authorization.
- Tests support both MySQL (default) and SQLite3 (unit tests only, via `database.github.sqlite3.yml`).

### Docker

`docker-compose.yml` runs seek + seek_workers + MySQL + Solr. For production-like local testing use `docker-compose up`. The `filestore/` directory (symlinked to `filestore-main/`) holds uploaded files; different `filestore-*` directories correspond to different DB configurations.
