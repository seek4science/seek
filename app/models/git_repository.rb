require 'git'

class GitRepository < ApplicationRecord
  belongs_to :resource, polymorphic: true, optional: true
  has_many :git_versions
  after_create :initialize_repository
  after_create :setup_remote, if: -> { remote.present? }

  validates :remote, uniqueness: { allow_nil: true }

  acts_as_uniquely_identifiable

  has_task :remote_git_fetch

  FETCH_SPACING = 15.minutes

  def local_path
    File.join(Seek::Config.git_filestore_path, uuid)
  end

  def git_base
    @git_base ||= Seek::Git::Base.base_class.new(local_path)
  end

  def fetch
    git_base.remotes['origin'].fetch
    touch(:last_fetch)
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
                         h = { name: name, ref: "refs/remotes/origin/#{name}", sha: info[:sha], default: info[:sha] == head }
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

  # Return the commit SHA for the given ref.
  def resolve_ref(ref)
    git_base.ref(ref)&.target&.oid
  end

  def remote?
    remote.present?
  end

  def queue_fetch(force = false)
    if remote.present?
      if force || last_fetch.nil? || last_fetch < FETCH_SPACING.ago
        RemoteGitFetchJob.perform_later(self)
      end
    end
  end

  private

  def initialize_repository
    Seek::Git::Base.base_class.init(local_path)
  end

  def setup_remote
    git_base.add_remote('origin', remote)
  end
end
