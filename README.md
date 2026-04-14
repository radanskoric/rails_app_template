# Rails Application Template

An opinionated, idempotent Rails application template for starting new projects with a standardized stack.

## What's Included

- **View rendering**: [ReActionView](https://github.com/nicholaides/reactionview) + [Herb](https://github.com/marcoroth/herb) for enhanced ERB templates
- **Styling**: Tailwind CSS
- **Database**: SQLite3 in all environments
- **Backups**: [Litestream](https://litestream.io/) for SQLite replication
- **Email (dev)**: [Letter Opener](https://github.com/ryanb/letter_opener) + [Letter Opener Web](https://github.com/fgrehm/letter_opener_web)
- **Logging (dev)**: [LogBench](https://github.com/fastruby/log_bench)
- **Console**: [AmazingPrint](https://github.com/amazing-print/amazing_print)
- **Testing**: Minitest (standard Rails) + Capybara for system tests
- **Deployment**: [dockerfile-rails](https://github.com/fly-apps/dockerfile-rails) gem
- **CI**: GitHub Actions (Brakeman, importmap audit, RuboCop, Minitest)
- **Dependencies**: Dependabot with sensible monthly grouping
- **Dev environment**: DevContainer with RustFS for local Litestream backup testing

## Usage

### Suggested `rails new` flags

The template **cannot** retroactively change options that are set at `rails new` time. I suggest passing the following flags:

| Flag                         | Why                                                          |
| ---------------------------- | ------------------------------------------------------------ |
| `--css=tailwind`             | Tailwind CSS setup (cannot be added after the fact)          |
| `--asset-pipeline=propshaft` | Uses Propshaft instead of Sprockets                          |
| `--skip-jbuilder`            | Not needed for this stack                                    |
| `--skip-bootsnap`            | Not used in this stack                                       |
| `--devcontainer`             | Generates `.devcontainer/` skeleton (template overwrites it) |

Or, given as a single line, including the template (assuming the template repo is cloned alongside the app):

```bash
rails new myapp --css=tailwind --asset-pipeline=propshaft --skip-jbuilder --skip-bootsnap --devcontainer -m ../rails_app_template/template.rb
```

### Apply to an existing application

```bash
bin/rails app:template LOCATION=path/to/rails_app_template/template.rb
```

## Idempotency

This template is designed to be **idempotent** — you can safely re-run it on an existing project. All mutations are guarded:

- Gems are only added if not already present in the Gemfile.
- File injections check for existing content before inserting.
- Static files are overwritten with canonical versions from the template.

This means you can update the template and re-apply it to bring existing projects up to date.

## Configuration

After applying the template, you'll want to configure:

- **Litestream**: Set `LITESTREAM_REPLICA_BUCKET`, `LITESTREAM_REPLICA_KEY_ID`, `LITESTREAM_REPLICA_KEY_SECRET`, and `LITESTREAM_REPLICA_ENDPOINT` environment variables for production.
- **DevContainer**: The default compose.yaml uses RustFS with default credentials. For the first run, log into RustFS at `localhost:9001` with the default keys and create a backup bucket.

## Development

The template's supporting code lives in `lib/`, with corresponding tests in `test/`.

```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rake test

# Run only fast unit tests
bundle exec rake test_unit

# Run only integration tests (slow — generates a full Rails app)
bundle exec rake test_integration
```

