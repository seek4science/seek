class WorkflowDiagram
  include Seek::MimeTypes

  class UnsupportedFormat < RuntimeError; end

  attr_reader :git_version, :path

  def initialize(git_version, path)
    @git_version = git_version
    @path = path
  end

  def filename
    "workflow-diagram-#{@git_version.resource_id}-#{@git_version.version}.#{extension}"
  end

  def extension
    path.split('.').last.downcase
  end

  def content_type
    mime_types_for_extension(extension).first
  end

  def size
    File.size(path)
  end

  def exists?
    File.exist?(path)
  end
end
