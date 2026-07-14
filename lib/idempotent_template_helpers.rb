# frozen_string_literal: true

# Idempotent overrides of Rails application template helpers.
#
# This module redefines `gem` and `inject_into_file` to be idempotent,
# delegating to the originals via `super` when work is needed.
#
# Designed to be `extend`ed in a Rails template context or `prepend`ed
# in tests. Set IdempotentTemplateHelpers.template_root before use.
module IdempotentTemplateHelpers
  class << self
    attr_accessor :template_root
  end
  def gem(name, *args, **options)
    gemfile_content = File.read("Gemfile")
    return if gemfile_content.include?("\"#{name}\"")
    super
  end

  def inject_into_file(file, content, **options)
    file_content = File.read(file)
    return if file_content.include?(content.strip)
    super
  end

  def read_template_file(source_path)
    File.read(File.join(IdempotentTemplateHelpers.template_root, "files", source_path))
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
