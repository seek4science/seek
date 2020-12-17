class GitVersion < ApplicationRecord
  class ImmutableVersionException < StandardError; end

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
    return unless commit
    if block_given?
      git_base.gblob("#{commit}:#{path}").contents(&block)
    else
      git_base.gblob("#{commit}:#{path}").contents
    end
  end

  def object(path)
    git_base.object("#{commit}:#{path}") if commit
  end

  def tree
    git_base.gtree(commit) if commit
  end

  def trees
    commit ? tree.trees : []
  end

  def blobs
    commit ? tree.blobs : []
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
    user_name, user_email = nil
    raise ImmutableVersionException unless mutable?
    user_name = git_base.config('user.name')
    user_email = git_base.config('user.email')
    git_base.config('user.name', User.current_user&.person&.name || Seek::Config.application_name)
    git_base.config('user.email', User.current_user&.person&.email || Seek::Config.noreply_sender)
    git_base.with_temp_working do |dir|
      git_base.checkout(commit) if commit
      yield dir
      git_base.commit(message)
      self.commit = git_base.revparse('HEAD')
    end
  ensure
    git_base.config('user.name', user_name)
    git_base.config('user.email', user_email)
  end

  def set_git_version_and_repo
    if @git_repository_remote
      self.git_repository = GitRepository.where(remote: @git_repository_remote).first_or_initialize
    else
      self.git_repository = resource.local_git_repository || resource.build_local_git_repository
    end
  end
end
