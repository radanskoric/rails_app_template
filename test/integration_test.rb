# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "open3"

# Integration test that applies the template to a real Rails application.
#
# This test is SLOW (generates a full Rails app + runs bundle install twice).
# Run separately with: bundle exec rake test_integration
class IntegrationTest < Minitest::Test
  TEMPLATE_PATH = File.expand_path("../../template.rb", __FILE__)
  RAILS_NEW_FLAGS = %w[
    --css=tailwind
    --asset-pipeline=propshaft
    --skip-jbuilder
    --skip-bootsnap
    --devcontainer
  ].freeze

  def setup
    @tmpdir = Dir.mktmpdir("template_integration")
    @app_dir = File.join(@tmpdir, "testapp")
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_template_applies_successfully
    generate_rails_app
    apply_template

    assert_gemfile_contains("reactionview")
    assert_gemfile_contains("herb")
    assert_gemfile_contains("litestream")
    assert_gemfile_contains("amazing_print")
    assert_gemfile_contains("capybara")
    assert_gemfile_contains("log_bench")
    assert_gemfile_contains("letter_opener")
    assert_gemfile_contains("simplecov")
    assert_gemfile_contains("dockerfile-rails")

    assert_file_exists("config/initializers/litestream.rb")
    assert_file_exists("config/initializers/log_bench.rb")
    assert_file_exists("config/initializers/reactionview.rb")
    assert_file_exists("config/litestream_development.yml")
    assert_file_exists("config/litestream_production.yml")
    assert_file_exists(".github/workflows/ci.yml")
    assert_file_exists(".github/dependabot.yml")
    assert_file_exists(".devcontainer/Dockerfile")
    assert_file_exists(".devcontainer/compose.yaml")
    assert_file_exists(".devcontainer/devcontainer.json")
    assert_file_exists("AGENTS.md")
    assert_file_exists("test/test_helper.rb")
    assert_file_exists("test/application_system_test_case.rb")

    routes = File.read(File.join(@app_dir, "config/routes.rb"))
    assert_includes routes, "LetterOpenerWeb"
    assert_includes routes, "Litestream"

    dev_env = File.read(File.join(@app_dir, "config/environments/development.rb"))
    assert_includes dev_env, ":letter_opener"
  end

  def test_template_is_idempotent
    generate_rails_app
    apply_template

    # Commit the first application
    run_in_app("git add -A && git commit -m 'first apply'")

    # Apply again
    apply_template

    # Check no changes were made
    diff_output = run_in_app("git diff")
    untracked = run_in_app("git ls-files --others --exclude-standard")

    assert_equal "", diff_output.strip, "Re-applying template produced diffs:\n#{diff_output}"
    assert_equal "", untracked.strip, "Re-applying template created untracked files:\n#{untracked}"
  end

  private

  def generate_rails_app
    cmd = "rails new testapp #{RAILS_NEW_FLAGS.join(" ")}"
    stdout, stderr, status = run_unbundled(cmd, chdir: @tmpdir)
    assert status.success?, "rails new failed:\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
  end

  def apply_template
    cmd = "bin/rails app:template LOCATION=#{TEMPLATE_PATH}"
    stdout, stderr, status = run_unbundled(cmd, chdir: @app_dir)
    assert status.success?, "Template application failed:\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
  end

  def run_in_app(cmd)
    stdout, stderr, status = run_unbundled(cmd, chdir: @app_dir)
    assert status.success?, "Command '#{cmd}' failed:\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    stdout
  end

  # Run a command with a clean environment, free of the template project's
  # Bundler context. This ensures `rails` and other gems installed globally
  # (or in the generated app's bundle) are found correctly.
  def run_unbundled(cmd, **options)
    if defined?(Bundler)
      Bundler.with_unbundled_env { Open3.capture3(cmd, **options) }
    else
      Open3.capture3(cmd, **options)
    end
  end

  def assert_gemfile_contains(gem_name)
    gemfile = File.read(File.join(@app_dir, "Gemfile"))
    assert_includes gemfile, "\"#{gem_name}\"", "Gemfile should contain gem '#{gem_name}'"
  end

  def assert_file_exists(relative_path)
    full_path = File.join(@app_dir, relative_path)
    assert File.exist?(full_path), "Expected file to exist: #{relative_path}"
  end
end
