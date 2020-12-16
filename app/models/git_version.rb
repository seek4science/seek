class GitVersion < ApplicationRecord
  class ImmutableVersionException < StandardError; end

  belongs_to :resource, polymorphic: true
  validates :target, presence: true

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

  def add_file(path, io)
    message = object(path) ? 'Updated' : 'Added'
    perform_commit("#{message} #{path}") do |dir|
      fullpath = Pathname.new(dir.path).join(path)
      File.write(fullpath, io.read)
      git_base.add(path)
    end
  end

  def freeze_version
    self.metadata = resource.attributes
    self.mutable = false
    save!
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

  def perform_commit(message, &block)
    raise ImmutableVersionException unless mutable?
    git_base.with_temp_working do |dir|
      git_base.checkout(commit)
      yield dir
      git_base.commit(message)
      self.commit = git_base.revparse('HEAD')
    end
  end
end
