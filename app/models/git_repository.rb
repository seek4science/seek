require 'git'

class GitRepository < ApplicationRecord
  belongs_to :resource, polymorphic: true, optional: true
  has_many :git_versions
  after_create :initialize_repository
  after_create :setup_remote, if: -> { remote.present? }

  acts_as_uniquely_identifiable

  def local_path
    File.join(Seek::Config.git_filestore_path, remote.present? ? uuid : "#{resource_type}-#{resource_id}")
  end

  def git_base
    return unless persisted?
    @git_base ||= Seek::Git::Base.base_class.new(Git.open(local_path))
  end

  def fetch
    git_base.fetch
  end

  # TODO: When active-job branch is merged, change this to use the TaskJob stuff instead:
  def fetching_status
    job = Delayed::Job.where("handler LIKE '%!ruby/object:RemoteGitCheckoutJob%'")
              .where("handler LIKE '%git_repository: #{id}%'").last
    if job
      if job.locked_at
        if job.failed_at
          :failed
        else
          :running
        end
      else
        :pending
      end
    else
      nil
    end
  end

  def fetching?
    [:pending, :running].include?(fetch_status)
  end

  def remote_refs
    @remote_refs ||= if remote.present?
                       refs = { branches: [], tags: [] }
                       hash = Git.ls_remote(remote)
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

  def find_ref(ref)
    remote_refs.each_value do |val|
      return val if ref == 'HEAD' && val[:default]
      return val if val[:ref] == ref
    end

    nil
  end

  private

  def initialize_repository
    Git.init(local_path)
  end

  def setup_remote
    git_base.add_remote('origin', remote)
    RemoteGitCheckoutJob.new(self).queue_job
  end
end
