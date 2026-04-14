# frozen_string_literal: true

# Idempotent helper methods for Rails application templates.
#
# This module is designed to be included in a Rails template context
# (where methods like `gem`, `gem_group`, `inject_into_file`,
# `create_file`, and `gsub_file` are available).
#
# Set TemplateHelpers.template_root before use.
module TemplateHelpers
  class << self
    attr_accessor :template_root
  end
  def add_gem_once(name, *args, **options)
    gemfile_content = File.read("Gemfile")
    return if gemfile_content.include?("\"#{name}\"")
    gem(name, *args, **options)
  end

  def add_gem_group_once(*groups, &block)
    gem_group(*groups, &block)
  end

  def inject_once(file, content, **options)
    file_content = File.read(file)
    return if file_content.include?(content.strip)
    inject_into_file(file, content, **options)
  end

  def read_template_file(source_path)
    File.read(File.join(TemplateHelpers.template_root, "files", source_path))
  end

  def create_or_replace_file(destination, source_path = nil, &block)
    if source_path
      content = read_template_file(source_path)
      create_file(destination, content, force: true)
    elsif block_given?
      create_file(destination, force: true, &block)
    end
  end

  def uncomment_lines_matching(file, pattern)
    gsub_file(file, /^(\s*)#\s*(#{pattern})/, '\1\2')
  end
end
