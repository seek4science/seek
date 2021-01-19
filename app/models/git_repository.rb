require 'git'

class GitRepository < ApplicationRecord
  belongs_to :resource, polymorphic: true, optional: true
  has_many :git_versions
  after_create :initialize_repository
  after_create :setup_remote, if: -> { remote.present? }

  acts_as_uniquely_identifiable

  has_task :remote_git_fetch

  def local_path
    File.join(Seek::Config.git_filestore_path, remote.present? ? uuid : "#{resource_type}-#{resource_id}")
  end

  def git_base
    return unless persisted?
    @git_base ||= Seek::Git::Base.base_class.new(local_path)
  end

  def fetch
    git_base.remotes['origin'].fetch
  end

  def fetching?
    remote_git_fetch_task && !remote_git_fetch_task.completed?
  end

  def remote_refs
    @remote_refs ||= if remote.present?
                       refs = { branches: [], tags: [] }
                       hash = Seek::Git::Base.base_class.ls_remote(remote)
                       head = hash['head'][:sha]
                       hash['branches'].each do |name, info|
                         h = { name: name, ref: "refs/heads/#{name}", sha: info[:sha], default: info[:sha] == head }
                         refs[:branches] << h
                       end
                       hash['tags'].each do |name, info|
                         h = { name: name, ref: "refs/tags/#{name}", sha: info[:sha] }
                         refs[:tags] << h
                       end

                       refs[:branches] = refs[:branches].sort_by { |x| [x[:default] ? 0 : 1, x[:name]] }
                       refs[:tags] = refs[:tags].sort_by { |x| x[:name] }

                       refs
                     end
  end

  def find_remote_ref(ref)
    remote_refs.each_value do |refs|
      refs.each do |val|
        return val[:sha] if ref == 'HEAD' && val[:default]
        return val[:sha] if val[:ref] == ref
      end
    end

    raise 'Ref not found!'
  end

  # Return the commit SHA for the given ref.
  # If local, fetch from the git db; if it's a remote repo, fetch using `ls-remote` to get an up-to-date reference
  def resolve_ref(ref)
    if remote?
      find_remote_ref(ref)
    else
      git_base.ref(ref)&.target
    end
  end

  def remote?
    remote.present?
  end

  private

  def initialize_repository
    Seek::Git::Base.base_class.init(local_path)
  end

  def setup_remote
    git_base.add_remote('origin', remote)
    RemoteGitFetchJob.perform_later(self)
  end
end
