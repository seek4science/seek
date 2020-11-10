class GitVersion < ApplicationRecord
  belongs_to :resource, polymorphic: true

  before_save :set_commit

  def metadata
    JSON.parse(super || '{}')
  end

  def metadata= m
    super(m.to_json)
  end

  def git_repository
    resource.git_repository
  end

  def git_base
    git_repository.git_base
  end

  def file_contents(path, &block)
    if block_given?
      git_base.gblob("#{commit}:#{path}").contents(&block)
    else
      git_base.gblob("#{commit}:#{path}").contents
    end
  end

  def object(path)
    git_base.object("#{commit}:#{path}")
  end

  def tree
    git_base.gtree(commit)
  end

  def trees
    tree.trees
  end

  def blobs
    tree.blobs
  end

  def latest_git_version?
    resource.latest_git_version == self
  end

  def is_a_version?
    true
  end

  private

  def set_commit
    self.commit ||= get_commit
  end

  def get_commit
    begin
      git_base.revparse(target) # Returns the SHA1 for the target (commit/branch/tag)
    rescue Git::GitExecuteError # Was it an origin branch that is not tracked locally?
      git_base.revparse("origin/#{target}")
    end
  end

  # Check metadata, and parent resource for missing methods. Allows GitVersions to be used as a drop-in replacement for
  #  Workflow::Version etc.
  def respond_to_missing?(name, include_private = false)
    metadata.key?(name.to_s) || resource.respond_to?(name) || super
  end

  def method_missing(method, *args, &block)
    if metadata.key?(method.to_s) && args.empty?
      metadata[method.to_s]
    elsif resource.respond_to?(method)
      resource.public_send(method, *args, &block)
    else
      super
    end
  end
end
