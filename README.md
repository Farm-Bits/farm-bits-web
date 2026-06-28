# Farm Bits

Farm Bits is a Ruby on Rails web application for monitoring and controlling agricultural sites
(greenhouses, fields, irrigation/fertigation systems, climate equipment) through a network of
PLCs and Modbus devices. It exposes a Vue 3 + Inertia.js single-page UI for administrators and
end users, a JSON API consumed by a mobile client, and a set of Sidekiq background workers
that handle polling, aggregation, archiving, alerting, and integrations with external
services (weather data, VPN manager, push notifications, etc.).

---

## Table of contents

1. [Technology stack](#technology-stack)
2. [System prerequisites](#system-prerequisites)
3. [External services](#external-services)
4. [Required configuration files](#required-configuration-files)
5. [Installation](#installation)
6. [Database setup and seeding](#database-setup-and-seeding)
7. [Running the application](#running-the-application)
8. [Background jobs and scheduler](#background-jobs-and-scheduler)
9. [Testing](#testing)
10. [Useful Rake tasks](#useful-rake-tasks)
11. [Default credentials](#default-credentials)
12. [Deployment](#deployment)
13. [Project layout](#project-layout)

---

## Technology stack

| Layer                | Technology                                                                     |
| -------------------- | ------------------------------------------------------------------------------ |
| Language / runtime   | Ruby **3.3.1** (see [.ruby-version](.ruby-version))                            |
| Web framework        | Rails **~> 7.2.1** (`load_defaults 7.2`)                                       |
| App server           | Puma **~> 6.4.1**                                                              |
| Database             | MySQL (via `mysql2 ~> 0.5`, `utf8mb4`)                                         |
| Cache / queue store  | Redis                                                                          |
| Background jobs      | Sidekiq + `sidekiq-scheduler` (queues: `critical`, `default`, `low`)           |
| Authentication       | Devise (`User` and `AdminUser`) with custom OTP flow and JWT for the mobile API |
| Authorization        | Pundit                                                                         |
| Rate limiting        | Rack::Attack                                                                   |
| Auditing             | `audited`                                                                      |
| Admin dashboards     | `administrate` (mounted under `/admin`)                                        |
| JSON serialization   | Blueprinter                                                                    |
| Frontend framework   | Vue **3.5** + Inertia.js (`@inertiajs/vue3`)                                   |
| State / routes       | Pinia (+ `pinia-plugin-persistedstate`), `js_from_routes`                      |
| UI kit               | CoreUI Vue + Tailwind CSS                                                      |
| Charts / maps        | ECharts (`vue-echarts`), Google Maps JS API                                    |
| Asset pipeline       | Vite (via `vite_rails` / `vite-plugin-ruby`) + TypeScript                      |
| Env vars             | Figaro (`config/application.yml`)                                              |
| HTTP                 | HTTParty                                                                       |
| Error reporting      | Bugsnag                                                                        |
| Push notifications   | OneSignal (custom mailer delivery method + push client)                        |
| Deployment           | Capistrano (rails, rvm, nvm, puma, sidekiq)                                    |
| Tests                | RSpec, FactoryBot, Faker, Timecop, `rails-controller-testing`                  |
| Node.js              | **22.13.0** (see [.node-version](.node-version))                               |

---

## System prerequisites

Install the following before setting up the project:

* **Ruby 3.3.1** — recommended via `rbenv` or `rvm`. The repository pins the version in
  [.ruby-version](.ruby-version).
* **Node.js 22.13.0** — recommended via `nvm` or `fnm`. Pinned in [.node-version](.node-version).
* **Bundler** — `gem install bundler`.
* **Yarn** (or `npm`) — Vite reads `yarn.lock`, so Yarn is preferred.
* **Foreman** — used by `bin/dev` to run Vite, Rails and Sidekiq side-by-side
  (`gem install foreman`).
* **MySQL 8.x** — the application uses MySQL with `utf8mb4` encoding. By default it expects
  a Unix socket at `/tmp/mysql.sock` (see [config/database.example.yml](config/database.example.yml)).
* **Redis** — required for Rails caching, Sidekiq queues and the scheduler. The default
  connection string is `redis://localhost:6379/0` (override with `REDIS_URL`).
* **libvips / ImageMagick** — required by Active Storage if you intend to attach/process images.
* **Git** with **Git LFS** — recommended for managing future binary assets.
* (macOS only) **Xcode Command Line Tools** for native gem compilation.

---

## External services

The application talks to several external systems. You can run it locally with these disabled,
but features that depend on them will be inert:

| Service             | Purpose                                              | Where it's configured                                                  |
| ------------------- | ---------------------------------------------------- | ---------------------------------------------------------------------- |
| PLC ingestion API   | Receives raw values from field PLCs                  | `PLC_INGESTION_*` env vars in `config/application.yml`                 |
| VPN manager         | Manages VPN credentials/tunnels for remote PLCs      | `VPN_MANAGER_*` env vars in `config/application.yml`                   |
| OneSignal           | Push notifications and transactional pushes          | `Rails.application.credentials[:onesignal]` (`app_id`, `api_key`)      |
| Google Maps         | Site map UI                                          | `VITE_GOOGLE_MAPS_API_KEY` in `.env`                                   |
| Google Places       | Address autocomplete                                 | `Rails.application.credentials[:google][:places_api_key]`              |
| GeoNames            | Timezone / location lookups                          | `Rails.application.credentials[:geonames][:username]`                  |
| IMS weather API     | Weather station data ingestion                       | `Rails.application.credentials[:ims][:api_token]`                      |
| Devise JWT secret   | Signing tokens for the mobile API                    | `Rails.application.credentials[:devise_jwt_secret_key]`                |
| Bugsnag             | Production exception reporting                       | `config/initializers/bugsnag.rb` (API key is hard-coded)               |

---

## Required configuration files

Several files are **not** checked in (see [.gitignore](.gitignore)) and must be created locally
before the app will boot.

### 1. `config/database.yml`

Copy the example and edit credentials:

```bash
cp config/database.example.yml config/database.yml
```

The template (see [config/database.example.yml](config/database.example.yml)) creates two
local databases — `farm_bits_development` and `farm_bits_test` — connected over the
`/tmp/mysql.sock` socket. Replace the `AAA`/`BBB`/`CCC`/`DDD` placeholders with real MySQL
credentials. A `production:` block is not provided in the example; add one only if you intend
to run the app in production locally.

### 2. `config/application.yml` (Figaro)

Copy the example and fill in the values you need:

```bash
cp config/application.example.yml config/application.yml
```

The template (see [config/application.example.yml](config/application.example.yml)) defines:

```yaml
development:
  HOSTNAME: localhost:3000

  ENABLE_PLC_INGESTION: 'false'
  PLC_INGESTION_BASE_URL: http://localhost:4000
  PLC_INGESTION_SERVICE_API_KEY: AAA
  PLC_INGESTION_CLIENT_API_KEY: BBB

  ENABLE_WRITE_VPN_MANAGER: 'false'
  VPN_MANAGER_BASE_URL: http://localhost:5000
  VPN_MANAGER_API_TOKEN: CCC
```

Add a `production:` block with the same keys when deploying.

### 3. `.env`

Copy the example and add the Google Maps key used by the Vite frontend:

```bash
cp .env.example .env
```

The template (see [.env.example](.env.example)) defines:

```
VITE_GOOGLE_MAPS_API_KEY=xxx
```

`VITE_*` vars are read by Vite at build time (`import.meta.env.VITE_GOOGLE_MAPS_API_KEY`).

### 4. Rails credentials (`config/master.key` and `config/credentials/*.key`)

The app uses **environment-scoped** encrypted credentials:

* `config/credentials/development.yml.enc` ↔ `config/credentials/development.key`
* `config/credentials/test.yml.enc`        ↔ `config/credentials/test.key`
* `config/credentials/production.yml.enc`  ↔ `config/credentials/production.key`

The `.key` files are git-ignored and must be obtained from a team member (out-of-band — 1Password,
Vault, etc.) and placed under `config/credentials/` before booting. The expected secret keys
inside the credentials files are:

```yaml
devise_jwt_secret_key: ...
onesignal:
  app_id: ...
  api_key: ...
google:
  places_api_key: ...
ims:
  api_token: ...
geonames:
  username: ...
```

Edit them with, e.g.:

```bash
EDITOR="code --wait" bin/rails credentials:edit --environment development
```

### 5. Optional environment variables

| Variable        | Default                       | Notes                                          |
| --------------- | ----------------------------- | ---------------------------------------------- |
| `REDIS_URL`     | `redis://localhost:6379/0`    | Used by Rails cache store and Sidekiq.         |
| `RAILS_ENV`     | `development`                 | Standard Rails env switch.                     |
| `RAILS_MAX_THREADS` | `5`                       | Connection pool size.                          |
| `PORT`          | `3000`                        | Used by `bin/dev`.                             |
| `CI`            | unset                         | When set, Rails eager-loads in `test` env.     |

---

## Installation

```bash
# 1. Clone the repo
git clone <repo-url> farmBits
cd farmBits

# 2. Install Ruby + Node toolchains (rbenv/nvm/asdf as you prefer)
# Make sure `ruby -v` reports 3.3.1 and `node -v` reports v22.13.0

# 3. Install gems
bundle install

# 4. Install JS dependencies
yarn install

# 5. Create the config files described above
cp config/database.example.yml config/database.yml
cp config/application.example.yml config/application.yml
cp .env.example .env
# ...and place credential keys under config/credentials/

# 6. Make sure MySQL and Redis are running
#    macOS (Homebrew):
#      brew services start mysql
#      brew services start redis
```

Once everything is in place, you can either run `bin/setup` (which runs `bundle check`,
`db:prepare`, clears logs and restarts the server) or perform the database setup manually
as shown below.

---

## Database setup and seeding

### Create the databases and run migrations

```bash
bin/rails db:create
bin/rails db:migrate
```

### Seed the database — full data set

The default `db/seeds.rb` only loads measurement types/subtypes, control groups, a default
admin user and a couple of base records. To get **the entire seed data set**, run the
following commands in this order:

```bash
rails db:seed
rails runner db/seeds/eliwell_free_advance_registers.rb
rails runner db/seeds/phase0_push_data_registers.rb
rails runner db/seeds/phase1_time_config_register.rb
rails runner db/seeds/phase2_global_registers.rb
rails runner db/seeds/phase3_io_health_registers.rb
rails runner db/seeds/phase4_operation_mode_registers.rb
rails runner db/seeds/modbus_host_slots.rb
rails runner db/seeds/modbus_registers_dcm230.rb
rails runner db/seeds/modbus_registers_sg3202.rb
rails runner db/seeds/modbus_registers_rs_fsxcs.rb
rails runner db/seeds/fatek_seedling_v2_4_2.rb

```

> ⚠️ The order matters: later seed files depend on records created by earlier ones (e.g. PLC
> versions, register templates, control groups and measurement subtypes).

The list of available seed scripts lives under [db/seeds/](db/seeds/).

### Resetting the database

```bash
bin/rails db:drop db:create db:migrate
# ...then re-run the seed commands above
```

---

## Running the application

### Development (all processes together)

The recommended way to run everything (Rails, Vite dev server, Sidekiq) is:

```bash
bin/dev
```

This uses Foreman with [Procfile.dev](Procfile.dev), which starts:

* `vite`  — `bin/vite dev`
* `web`   — `bin/rails s -b 0.0.0.0 -p 3000`
* `worker` — `bundle exec sidekiq`

Then visit <http://localhost:3000>.

### Running pieces individually

```bash
bin/rails server          # Rails only
bin/vite dev              # Vite dev server (HMR)
bundle exec sidekiq       # Background jobs
```

### Admin dashboard

Mounted at `/admin` and only accessible to authenticated `AdminUser` records. The default
admin created by `db/seeds.rb` is:

* Email: `jeremy@farm-bits.com`
* Password: `Jeremy123`

Change this immediately for any non-local environment.

### Sidekiq Web UI

Mounted at `/sidekiq`, available to authenticated `AdminUser` only.

---

## Background jobs and scheduler

`sidekiq-scheduler` is configured in [config/sidekiq.yml](config/sidekiq.yml). Note that
**scheduled jobs are disabled outside production by default** (`enabled: <%= ENV['RAILS_ENV'] == 'production' %>`).

Scheduled jobs include:

| Job                                  | Cron            | Queue    |
| ------------------------------------ | --------------- | -------- |
| `PlcSyncJob`                         | `0 3 * * *`     | critical |
| `ModbusPollingJob`                   | `* * * * *`     | default  |
| `SiteSunDataSyncJob`                 | `0 2 * * *`     | default  |
| `WeatherStationApiImsFetchJob`       | `*/10 * * * *`  | default  |
| `HourlyAggregationJob`               | `5 * * * *`     | low      |
| `WeatherStationApiHourlyAggregationJob` | `5 * * * *`  | low      |
| `AlertInactivityScanJob`             | `* * * * *`     | default  |
| `ArchiveJob`                         | `0 3 * * *`     | low      |

---

## Testing

The test framework is **RSpec** with FactoryBot and Faker.

```bash
# Prepare the test database (uses config/database.yml > test)
bin/rails db:test:prepare

# Run the full suite
bundle exec rspec

# Run a single file
bundle exec rspec spec/models/user_spec.rb

# Smoke tests are excluded by default (config.filter_run_excluding :smoke)
bundle exec rspec --tag smoke
```

Test layout:

* `spec/models/`, `spec/requests/`, `spec/lib/`, `spec/mailers/` — standard RSpec specs.
* `spec/factories/` — FactoryBot factories.
* `spec/support/` — shared helpers (auto-required from `spec/rails_helper.rb`).
* `spec/smoke/` — slower end-to-end checks (opt-in via `--tag smoke`).
* `spec/integration/` — cross-component integration specs.

---

## Useful Rake tasks

```bash
# List all rake tasks
bin/rails -T

# Verify a Modbus firmware version configuration (see lib/tasks/modbus.rake)
bin/rails modbus:verify[<modbus_firmware_version_id>]

# Generate the frontend permissions matrix (lib/tasks/generate_frontend_permissions.rb)
bin/rails permissions:generate_frontend  # task name may vary; check the file

# Generate an ER diagram from Active Record models (rails-erd gem)
bin/rails erd
```

---

## Default credentials

After seeding, the following login is available:

| Role        | Email                  | Password    |
| ----------- | ---------------------- | ----------- |
| AdminUser   | `jeremy@farm-bits.com` | `Jeremy123` |

These are development-only defaults. **Do not** use them outside local development.

---

## Deployment

Deployment is handled by **Capistrano** (see [Capfile](Capfile) and [config/deploy.rb](config/deploy.rb)).
The configuration uses:

* `capistrano-rails` — asset and migration tasks
* `capistrano-rvm` — Ruby version management on the server
* `capistrano-nvm` — Node version management on the server
* `capistrano3-puma` — Puma process management
* `capistrano-sidekiq` — Sidekiq process management

Typical commands:

```bash
bundle exec cap production deploy
bundle exec cap production deploy:check
bundle exec cap staging deploy   # if a staging stage is defined
```

Stages live under [config/deploy/](config/deploy/). Make sure `config/application.yml` and
the encrypted credentials are present on the target server (typically symlinked from the
shared directory).

---

## Project layout

```
app/
├── assets/         # Sprockets-served assets (mostly empty; Vite handles JS/CSS)
├── builders/       # Service-style record builders
├── clients/        # HTTP clients (PLC ingestion, VPN manager, OneSignal, IMS, GeoNames, ...)
├── controllers/    # Rails controllers (incl. api/mobile/v1, api/v1, admin_area, login)
├── frontend/       # Vue 3 + Inertia.js SPA (entry: app/frontend/app.ts)
│   ├── api/        # js_from_routes generated clients
│   ├── components/
│   ├── composables/
│   ├── layouts/
│   ├── pages/      # Inertia pages
│   ├── stores/     # Pinia stores
│   ├── styles/     # Tailwind + global styles
│   └── types/
├── jobs/           # Sidekiq jobs (PlcSyncJob, ModbusPollingJob, alerts, archive, etc.)
├── mailboxes/      # Action Mailbox routes
├── mailers/        # ActionMailer + OneSignal delivery method
├── models/         # Active Record models, incl. modbus_behaviors/
├── policies/       # Pundit policies
├── queries/        # Reusable Active Record query objects
├── serializers/    # Blueprinter serializers
└── services/       # Domain services

config/
├── application.example.yml   # Figaro template
├── database.example.yml      # MySQL template
├── credentials/              # Per-env encrypted credentials
├── deploy/                   # Capistrano stages
├── initializers/             # devise, sidekiq, rack_attack, bugsnag, inertia_rails, onesignal, ...
├── routes.rb
└── sidekiq.yml               # Sidekiq queues + scheduler

db/
├── migrate/                  # Schema migrations
├── seeds.rb                  # Base seed (measurement types, control groups, admin user)
└── seeds/                    # Additional seed scripts (phases, modbus registers, fatek)

lib/tasks/                    # Custom rake tasks (modbus.rake, generate_frontend_permissions.rb)

spec/                         # RSpec test suite (models, requests, lib, mailers, support, ...)
```

---

## Getting help

* `bin/rails routes` — full route list.
* `bin/rails console` — interactive Rails console.
* `tail -f log/development.log` — server logs.
* Bugsnag dashboard — exceptions in production.
* `/sidekiq` — background job monitoring (admin-only).
