# A class that responds to the same methods that a SEEK resource (e.g. DataFile), but using the metadata from a GitVersion
class ResourceProxy
  def initialize(resource, git_version)
    @resource = resource
    @git_version = git_version
  end

  # Check metadata, and parent resource for missing methods. Allows a Workflow::ResourceProxy to be used as a drop-in replacement for
  #  Workflow::Version etc.
  def respond_to_missing?(name, include_private = false)
    @git_version.metadata.key?(name.to_s) || @resource.respond_to?(name) || super
  end

  def method_missing(method, *args, &block)
    if @git_version.metadata.key?(method.to_s) && args.empty?
      @git_version.metadata[method.to_s]
    elsif @resource.respond_to?(method)
      @resource.public_send(method, *args, &block)
    else
      super
    end
  end
end
