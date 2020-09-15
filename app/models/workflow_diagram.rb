class WorkflowDiagram
  class UnsupportedFormat < RuntimeError; end

  attr_reader :workflow, :version, :path, :format, :content_type

  def initialize(workflow, version, path, format, content_type)
    @workflow = workflow
    @version = version
    @path = path
    @format = format
    @content_type = content_type
  end

  def filename
    "workflow-diagram-#{@workflow.id}-#{@version}.#{@format}"
  end

  def size
    File.size(@path)
  end

  def exists?
    File.exist?(@path)
  end
end
