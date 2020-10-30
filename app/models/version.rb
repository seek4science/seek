class Version < ApplicationRecord
  belongs_to :resource, polymorphic: true

  before_save :set_commit

  def git_repository
    resource.git_repository
  end

  def git_base
    git_repository.git_base
  end

  def list_files
    git_base.ls_files
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

  private

  def set_commit
    self.commit ||= git_base.revparse(target) # Returns the SHA1 for the target (commit/branch/tag)
  end
end