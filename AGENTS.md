# AGENTS.md

Instructions for AI coding agents working on this project.

## What This Project Is

This is a **Rails application template** — a Ruby script (`template.rb`) that modifies a Rails application to set up a standardized development stack. It is NOT a Rails application itself.

The template is designed to be applied to new or existing Rails apps via:
```bash
rails new myapp -m template.rb
bin/rails app:template LOCATION=template.rb
```

## Purpose

This template provides a consistent starting point for new Rails applications with:
- ReActionView + Herb for view rendering
- Tailwind CSS for styling
- SQLite3 in all environments with Litestream for backups
- Letter Opener for dev email
- LogBench for dev logging
- AmazingPrint for console QoL
- Minitest + Capybara for testing
- GitHub Actions CI, Dependabot, and DevContainer setup

## Repository Structure

```
rails_app_template/
├── template.rb       # Main template script — orchestrates all steps
├── lib/              # Supporting Ruby code
│   └── template_helpers.rb  # Idempotent helper methods (module)
├── files/            # Static files copied verbatim into target apps
│   ├── config/
│   │   ├── initializers/    # litestream.rb, log_bench.rb, reactionview.rb
│   │   ├── litestream_development.yml
│   │   └── litestream_production.yml
│   ├── test/                # test_helper.rb, application_system_test_case.rb
│   ├── .github/             # CI workflow, dependabot config
│   └── .devcontainer/       # Dockerfile, compose.yaml, devcontainer.json
├── test/             # Tests for the template itself
│   ├── test_helper.rb
│   ├── template_helpers_test.rb  # Unit tests for helpers
│   └── integration_test.rb       # Full apply + idempotency test
├── Gemfile
├── Rakefile
├── README.md
└── AGENTS.md
```

## Idempotency — CRITICAL

**Every action in `template.rb` MUST be idempotent.** Running the template twice on the same application must produce the exact same result as running it once. No duplicate gems, no duplicate file injections, no errors.

### How idempotency is enforced

The template uses helper methods defined in `lib/template_helpers.rb`:

- **`add_gem_once(name, ...)`** — Adds a gem only if it's not already in the Gemfile. Always use this instead of bare `gem()`.
- **`inject_once(file, content, ...)`** — Injects content into a file only if the content isn't already present. Always use this instead of bare `inject_into_file()`.
- **`create_or_replace_file(destination, source)`** — Creates or overwrites a file with content from `files/`. Use for static files that should match the template exactly.
- **`uncomment_lines_matching(file, pattern)`** — Uncomments lines matching a pattern. Safe to re-run since already-uncommented lines won't match the commented pattern.

### Rules for contributors

1. **Never use bare `gem()`, `inject_into_file()`, or `route()`** — always use the idempotent wrappers.
2. **Always test idempotency**: apply the template to a fresh `rails new` app, then apply it again. The second run should produce zero changes.
3. **Static files go in `files/`** — avoid heredocs in `template.rb` for multi-line file content.
4. **Guard conditional modifications** — when using `gsub_file`, ensure the pattern handles both the original and already-modified states.

### Testing changes

```bash
# Run all tests (unit + integration)
bundle exec rake test

# Run only fast unit tests for helpers
bundle exec rake test_unit

# Run only integration tests (slow — generates a full Rails app)
bundle exec rake test_integration
```

The integration test automatically creates a fresh Rails app, applies the template, verifies key outcomes, then re-applies and checks that `git diff` is empty (idempotency).

## Code Style

- Keep `template.rb` organized with clear section comments matching the step numbers.
- Use the existing helper methods; add new ones if a new idempotency pattern is needed.
- Prefer `create_or_replace_file` with static files in `files/` over inline content in `template.rb`.
