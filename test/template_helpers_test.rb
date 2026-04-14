# frozen_string_literal: true

require_relative "test_helper"

class AddGemOnceTest < TemplateHelpersTestCase
  def test_adds_gem_when_not_present
    File.write("Gemfile", <<~GEMFILE)
      source "https://rubygems.org"
      gem "rails"
    GEMFILE

    add_gem_once "sidekiq"

    assert_equal 1, @gem_calls.size
    assert_equal "sidekiq", @gem_calls.first[:name]
  end

  def test_skips_gem_when_already_present
    File.write("Gemfile", <<~GEMFILE)
      source "https://rubygems.org"
      gem "sidekiq"
    GEMFILE

    add_gem_once "sidekiq"

    assert_empty @gem_calls
  end

  def test_passes_version_constraint
    File.write("Gemfile", <<~GEMFILE)
      source "https://rubygems.org"
    GEMFILE

    add_gem_once "sidekiq", "~> 7.0"

    assert_equal 1, @gem_calls.size
    assert_equal ["~> 7.0"], @gem_calls.first[:args]
  end

  def test_passes_group_option
    File.write("Gemfile", <<~GEMFILE)
      source "https://rubygems.org"
    GEMFILE

    add_gem_once "sidekiq", group: :development

    assert_equal 1, @gem_calls.size
    assert_equal({ group: :development }, @gem_calls.first[:options])
  end

  def test_detects_gem_inside_group_block
    File.write("Gemfile", <<~GEMFILE)
      source "https://rubygems.org"
      group :development do
        gem "sidekiq"
      end
    GEMFILE

    add_gem_once "sidekiq"

    assert_empty @gem_calls
  end

  def test_does_not_match_substring_gem_names
    File.write("Gemfile", <<~GEMFILE)
      source "https://rubygems.org"
      gem "sidekiq-pro"
    GEMFILE

    add_gem_once "sidekiq"

    assert_equal 1, @gem_calls.size
    assert_equal "sidekiq", @gem_calls.first[:name]
  end
end

class InjectOnceTest < TemplateHelpersTestCase
  def test_injects_when_content_not_present
    File.write("routes.rb", <<~RUBY)
      Rails.application.routes.draw do
      end
    RUBY

    inject_once "routes.rb", "  mount Foo::Engine\n", before: /^end/

    assert_equal 1, @inject_calls.size
    assert_equal "routes.rb", @inject_calls.first[:file]
  end

  def test_skips_when_content_already_present
    File.write("routes.rb", <<~RUBY)
      Rails.application.routes.draw do
        mount Foo::Engine
      end
    RUBY

    inject_once "routes.rb", "  mount Foo::Engine\n", before: /^end/

    assert_empty @inject_calls
  end

  def test_strips_whitespace_when_checking
    File.write("routes.rb", <<~RUBY)
      Rails.application.routes.draw do
        mount Foo::Engine
      end
    RUBY

    inject_once "routes.rb", "\n  mount Foo::Engine\n", before: /^end/

    assert_empty @inject_calls
  end
end

class ReadTemplateFileTest < TemplateHelpersTestCase
  def setup
    super
    TemplateHelpers.template_root = File.expand_path("../..", __FILE__)
  end

  def test_reads_file_from_files_directory
    content = read_template_file("test/test_helper.rb")
    assert_includes content, "simplecov"
  end

  def test_raises_for_missing_file
    assert_raises(Errno::ENOENT) do
      read_template_file("nonexistent.rb")
    end
  end
end

class CreateOrReplaceFileTest < TemplateHelpersTestCase
  def setup
    super
    TemplateHelpers.template_root = File.expand_path("../..", __FILE__)
  end

  def test_creates_file_from_source_path
    create_or_replace_file "test/test_helper.rb", "test/test_helper.rb"

    assert_equal 1, @create_file_calls.size
    call = @create_file_calls.first
    assert_equal "test/test_helper.rb", call[:destination]
    assert_includes call[:content], "simplecov"
    assert_equal true, call[:options][:force]
  end

  def test_creates_file_from_block
    create_or_replace_file("foo.rb") { "puts 'hello'" }

    assert_equal 1, @create_file_calls.size
    assert_equal "foo.rb", @create_file_calls.first[:destination]
  end
end

class UncommentLinesMatchingTest < TemplateHelpersTestCase
  def test_delegates_to_gsub_file
    uncomment_lines_matching("config/application.rb", 'require "rails/test_unit/railtie"')

    assert_equal 1, @gsub_file_calls.size
    assert_equal "config/application.rb", @gsub_file_calls.first[:file]
  end
end
