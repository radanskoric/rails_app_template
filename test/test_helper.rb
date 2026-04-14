# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require_relative "../lib/template_helpers"

# A test harness that simulates the Rails template generator context.
# It includes TemplateHelpers and provides stub implementations of the
# Rails generator methods that the helpers depend on.
class TemplateHelpersTestCase < Minitest::Test
  include TemplateHelpers

  def setup
    @tmpdir = Dir.mktmpdir("template_test")
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    # Track calls to stubbed Rails generator methods
    @gem_calls = []
    @gem_group_calls = []
    @inject_calls = []
    @create_file_calls = []
    @gsub_file_calls = []
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.remove_entry(@tmpdir)
  end

  private

  # Stub: Rails generator `gem` method
  def gem(name, *args, **options)
    @gem_calls << { name: name, args: args, options: options }
  end

  # Stub: Rails generator `gem_group` method
  def gem_group(*groups, &block)
    @gem_group_calls << { groups: groups }
    block&.call
  end

  # Stub: Rails generator `inject_into_file` method
  def inject_into_file(file, content = nil, **options)
    @inject_calls << { file: file, content: content, options: options }
  end

  # Stub: Rails generator `create_file` method
  def create_file(destination, content = nil, **options, &block)
    content = block&.call if block_given?
    @create_file_calls << { destination: destination, content: content, options: options }
  end

  # Stub: Rails generator `gsub_file` method
  def gsub_file(file, pattern, replacement)
    @gsub_file_calls << { file: file, pattern: pattern, replacement: replacement }
  end
end
