require 'git'

class GitRepository < ApplicationRecord
  belongs_to :resource, polymorphic: true

  def local_path
    File.join(Seek::Config.git_filestore_path, uuid)
  end

  def git_base
    @git_base ||= Git.init(local_path)
  end

  def clone_repo
    Git.clone(remote, uuid, path: Seek::Config.git_filestore_path)
  end
end