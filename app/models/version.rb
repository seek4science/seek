class Version
  DUMMY = {
      commit: '36208e44ccaa5ecf584a3b8680cdbd9c3da31f98',
  }

  attr_accessor :commit

  def initialize(args = DUMMY)
    @commit = args[:commit]
  end

  def git_repository
    #asset.git_repository.git_base
    GitRepository.new
  end

  def git_base
    @git_base ||= Git.open(git_repository.local_path)
  end

  def local_path
    File.join(Seek::Config.git_temporary_filestore_path, git_repository.uuid, sha)
  end

  def resolve(*path)
    with_worktree do
      File.join(local_path, path)
    end
  end

  def with_worktree
    w = worktree
    if w.nil?
      add_worktree
    elsif !File.exist(w.dir)
      remove_worktree
      add_worktree
    end

    yield
  end

  def worktree
    git_base.worktrees[worktree_id]
  end

  def add_worktree
    git_base.worktree(local_path, sha).add
  end

  def remove_worktree
    git_base.worktree(local_path, sha).remove
  end

  # Returns the SHA1 for the commit/branch/tag
  def sha
    git_base.revparse(commit)
  end

  def tree
    git_base.gtree(sha)
  end

  def trees
    tree.trees
  end

  def blobs
    tree.blobs
  end

  private

  def worktree_id
    "#{local_path} #{sha}"
  end
end