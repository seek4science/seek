require 'git'

class GitRepository
  DUMMY = {
      remote: 'https://github.com/seek4science/DOI-query-tool.git',
      uuid: 'c7b5ca02-4227-47c0-9597-c3399702883f'
  }

  attr_accessor :remote, :uuid

  def initialize(args = DUMMY)
    @remote = args[:remote]
    @uuid = args[:uuid]
  end

  def local_path
    File.join(Seek::Config.git_filestore_path, uuid)
  end

  def base
    @base ||= Git.init(local_path)
  end

  def clone_repo
    Git.clone(remote, uuid, path: Seek::Config.git_filestore_path)
  end
end