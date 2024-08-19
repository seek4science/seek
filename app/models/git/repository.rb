module Git
  class Repository < ApplicationRecord
    belongs_to :resource, polymorphic: true, optional: true, inverse_of: :local_git_repository
    has_many :git_versions, class_name: 'Git::Version', foreign_key: :git_repository_id, dependent: :destroy
    after_create :initialize_repository
    after_create :setup_remote, if: -> { remote.present? }
    after_destroy :disk_cleanup

    validates :remote, uniqueness: { allow_nil: true }

    acts_as_uniquely_identifiable

    has_task :remote_git_fetch

    FETCH_SPACING = 15.minutes

    def self.redundant
      self.left_outer_joins(:git_versions).where(git_versions: { id: nil })
    end

    def local_path
      File.join(Seek::Config.git_filestore_path, uuid)
    end

    def git_base
      @git_base ||= Git::Base.base_class.new(local_path)
    end

    def fetch
      git_base.remotes['origin'].fetch
      touch(:last_fetch)
    end

    def remote_refs
      @remote_refs ||= if remote.present?
                         refs = { branches: [], tags: [] }

                         git_base.branches.each do |branch|
                           next unless branch.remote?
                           # TODO: Fix the default branch check. Does not seem to be a way to do in Rugged.
                           name = branch.name.sub(/\A#{branch.remote_name}\//, '')
                           h = { name: name, ref: branch.canonical_name, sha: branch.target.oid }
                           h[:default] = true if ['main', 'master', 'develop'].include?(name)
                           refs[:branches] << h
                         end

                         git_base.tags.to_a.sort_by do |tag|
                           tag.target.time
                         end.reverse.each do |tag|
                           h = { name: tag.name, ref: tag.canonical_name, sha: tag.target.oid }
                           refs[:tags] << h
                         end

                         refs[:branches] = refs[:branches].sort_by { |x| [x[:default] ? 0 : 1, x[:name].downcase] }

                         refs
                       end
    end

    # Return the commit SHA for the given ref.
    def resolve_ref(ref)
      t = git_base.ref(ref)&.target
      t = t.target if t.is_a?(Rugged::Tag::Annotation)
      t&.oid
    end

    def remote?
      remote.present?
    end

    def queue_fetch(force = false)
      if remote.present?
        if force || last_fetch.nil? || last_fetch < FETCH_SPACING.ago
          Seek::Config.immediate_git_fetch ? RemoteGitFetchJob.perform_now(self) : RemoteGitFetchJob.perform_later(self)
        end
      end
    end

    private

    def initialize_repository
      Git::Base.base_class.init(local_path)
    end

    def setup_remote
      git_base.add_remote('origin', remote)
    end

    def disk_cleanup
      FileUtils.rm_rf(local_path) if local_path && local_path.length > 36 # Length check for safety
    end
  end
end
