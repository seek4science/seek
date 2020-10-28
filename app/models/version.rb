class Version < ApplicationRecord
  belongs_to :resource, polymorphic: true

  before_save :set_commit

  def git_repository
    #resource.git_repository
    GitRepository.last
  end

  def git_base
    @git_base ||= Git.open(git_repository.local_path)
  end

  def local_path
    File.join(Seek::Config.git_temporary_filestore_path, git_repository.uuid, sha)
  end

  def list_files
    git_base.ls_files
  end

  def file_contents(path, &block)
    if block_given?
      git_base.gblob("#{sha}:#{path}").contents(&block)
    else
      git_base.gblob("#{sha}:#{path}").contents
    end
  end

  def object(path)
    git_base.object("#{sha}:#{path}")
  end

  # def resolve(*path)
  #   with_worktree do
  #     File.join(local_path, path)
  #   end
  # end
  #
  # def with_worktree
  #   w = worktree
  #   if w.nil?
  #     add_worktree
  #   elsif !File.exist(w.dir)
  #     remove_worktree
  #     add_worktree
  #   end
  #
  #   yield
  # end
  #
  # def worktree
  #   git_base.worktrees[worktree_id]
  # end
  #
  # def add_worktree
  #   git_base.worktree(local_path, sha).add
  # end
  #
  # def remove_worktree
  #   git_base.worktree(local_path, sha).remove
  # end

  # Returns the SHA1 for the commit/branch/tag
  def sha
    git_base.revparse(commit)
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

  private

  def set_commit
    self.commit ||= git_base.revparse(target) # Returns the SHA1 for the target (commit/branch/tag)
  end

  #
  # def worktree_id
  #   "#{local_path} #{sha}"
  # end
end