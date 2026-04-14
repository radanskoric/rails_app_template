# Rails Application Template
# https://github.com/radanskoric/rails_app_template
#
# Usage:
#   rails new myapp -m path/to/template.rb
#   bin/rails app:template LOCATION=path/to/template.rb
#
# This template is idempotent — safe to re-run on existing projects.

require_relative "lib/template_helpers"
TemplateHelpers.template_root = __dir__
extend TemplateHelpers

# =============================================================================
# Step 2: Gems
# =============================================================================

# View rendering
add_gem_once "reactionview"
add_gem_once "herb", "~> 0.9"

# Database backup/restore
add_gem_once "litestream", "~> 0.14.0"

# QoL for developers
add_gem_once "amazing_print"

# Deployment
add_gem_once "dockerfile-rails", ">= 1.7", group: :development

# Testing
add_gem_once "capybara", group: [:development, :test]
add_gem_once "simplecov", group: :test

# Dev tools
add_gem_once "log_bench", group: :development
add_gem_once "letter_opener", group: :development
add_gem_once "letter_opener_web", "~> 3.0", group: :development

# =============================================================================
# Step 3: Initializers
# =============================================================================

create_or_replace_file "config/initializers/litestream.rb", "config/initializers/litestream.rb"
create_or_replace_file "config/initializers/log_bench.rb", "config/initializers/log_bench.rb"
create_or_replace_file "config/initializers/reactionview.rb", "config/initializers/reactionview.rb"

# =============================================================================
# Step 4: Litestream config files
# =============================================================================

create_or_replace_file "config/litestream_development.yml", "config/litestream_development.yml"
create_or_replace_file "config/litestream_production.yml", "config/litestream_production.yml"

# =============================================================================
# Step 5: Development environment config
# =============================================================================

dev_env_file = "config/environments/development.rb"
dev_content = File.read(dev_env_file)

unless dev_content.include?(":letter_opener")
  if dev_content.match?(/config\.action_mailer\.delivery_method\s*=/)
    gsub_file dev_env_file,
      /config\.action_mailer\.delivery_method\s*=.*$/,
      "config.action_mailer.delivery_method = :letter_opener"
  else
    inject_once dev_env_file,
      "\n  config.action_mailer.delivery_method = :letter_opener\n",
      before: /^end/
  end

  inject_once dev_env_file,
    "  config.action_mailer.perform_deliveries = true\n",
    after: "config.action_mailer.delivery_method = :letter_opener\n"
end

# =============================================================================
# Step 6: Routes
# =============================================================================

routes_file = "config/routes.rb"
routes_content = File.read(routes_file)

unless routes_content.include?("LetterOpenerWeb")
  inject_once routes_file,
    "\n  mount LetterOpenerWeb::Engine, at: \"/letter_opener\" if Rails.env.development?\n",
    before: /^end/
end

unless routes_content.include?("Litestream")
  inject_once routes_file,
    "  mount Litestream::Engine, at: \"/litestream\" if Rails.env.development?\n",
    before: /^end/
end

# =============================================================================
# Step 7: Enable test_unit railtie
# =============================================================================

app_rb = "config/application.rb"
uncomment_lines_matching(app_rb, 'require "rails/test_unit/railtie"')

# =============================================================================
# Step 8: GitHub Actions CI workflow
# =============================================================================

create_or_replace_file ".github/workflows/ci.yml", ".github/workflows/ci.yml"

# =============================================================================
# Step 9: Dependabot configuration
# =============================================================================

create_or_replace_file ".github/dependabot.yml", ".github/dependabot.yml"

# =============================================================================
# Step 10: DevContainer setup
# =============================================================================

create_or_replace_file ".devcontainer/Dockerfile", ".devcontainer/Dockerfile"
create_or_replace_file ".devcontainer/compose.yaml", ".devcontainer/compose.yaml"
create_or_replace_file ".devcontainer/devcontainer.json", ".devcontainer/devcontainer.json"

# =============================================================================
# Step 11: after_bundle
# =============================================================================

after_bundle do
  # Create AGENTS.md for coding agents
  create_or_replace_file "AGENTS.md", "AGENTS.md"

  # Ensure test directory structure exists
  run "mkdir -p test/system test/models test/controllers test/helpers test/integration"

  # Create test_helper.rb with Capybara support
  create_or_replace_file "test/test_helper.rb", "test/test_helper.rb"

  # Create application_system_test_case.rb
  create_or_replace_file "test/application_system_test_case.rb", "test/application_system_test_case.rb"

  # Auto-correct code style
  run "bundle exec rubocop -A --fail-level=E" rescue nil
end
