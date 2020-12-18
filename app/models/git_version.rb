class GitVersion < ApplicationRecord
  class ImmutableVersionException < StandardError; end

  include Seek::Git

  attr_writer :git_repository_remote
  belongs_to :resource, polymorphic: true
  belongs_to :git_repository
  before_validation :set_git_version_and_repo, on: :create
  before_save :set_commit, unless: -> { target.blank? }

  def metadata
    JSON.parse(super || '{}')
  end

  def metadata= m
    super(m.to_json)
  end

  def git_base
    git_repository.git_base
  end

  def file_contents(path, &block)
    blob = object(path)
    return unless blob&.blob?

    if block_given?
      blob.contents(&block)
    else
      blob.contents
    end
  end

  def object(path)
    git_base.object("#{commit}:#{path}") if commit
  end

  def tree
    git_base.gtree(commit) if commit
  end

  def trees
    tree&.trees || []
  end

  def blobs
    tree&.blobs || []
  end

  def latest_git_version?
    resource.latest_git_version == self
  end

  def is_a_version?
    true
  end

  def file_exists?(path)
    subtree = tree
    path.split('/').each do |segment|
      return false unless subtree && subtree.children.key?(segment)
      subtree = subtree.children[segment]
    end

    true
  end

  def add_file(path, io)
    message = file_exists?(path) ? 'Updated' : 'Added'
    perform_commit("#{message} #{path}") do |dir|
      fullpath = Pathname.new(dir.path).join(path)
      FileUtils.mkdir_p(fullpath.dirname)
      File.write(fullpath, io.read)
      git_base.add(path)
    end
  end

  def freeze_version
    self.metadata = resource.attributes
    self.mutable = false
    save!
  end

  def proxy
    resource.class.proxy_class.new(resource, self)
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

    with_git_user do
      git_base.with_temp_working do |dir|
        git_base.checkout(commit) if commit
        yield dir
        git_base.commit(message)
        self.commit = git_base.revparse('HEAD')
      end
    end
  end

  def set_git_version_and_repo
    if @git_repository_remote
      self.git_repository = GitRepository.where(remote: @git_repository_remote).first_or_initialize
    else
      self.git_repository = resource.local_git_repository || resource.build_local_git_repository
    end
  end
end
