class WorkflowDiagram
  include Seek::MimeTypes

  attr_reader :workflow, :path

  def initialize(workflow, path)
    @workflow = workflow
    @path = path
  end

  def filename
    "#{workflow.cache_key_fragment}-diagram.#{extension}"
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

  def sha1sum
    digest = Digest::SHA1.new
    digest.file(path)
    digest.hexdigest
  end

  def to_crate_entity(crate, type: ::RoCrate::WorkflowDiagram, properties: {})
    type.new(crate, path, filename).tap do |entity|
      entity['contentSize'] = size
      entity.properties = entity.raw_properties.merge(properties)
    end
  end
end
