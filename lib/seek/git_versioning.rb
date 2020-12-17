module Seek
  module GitVersioning
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def git_versioning(options = {}, &extension)
        # don't allow multiple calls
        return if reflect_on_association(:git_versions)

        cattr_accessor :proxy_class_name
        self.proxy_class_name = options[:proxy_class_name]  || 'ResourceProxy'

        class_eval do
          has_many :git_versions, as: :resource, dependent: :destroy
          has_one :local_git_repository, as: :resource, class_name: 'GitRepository'
          # after_create :save_version_on_create
          # after_update :sync_latest_version

          delegate :git_base, :file_contents, :object, :commit, :tree, :trees, :blobs, to: :latest_git_version

          def latest_git_version
            git_versions.last
          end

          # def git_working_path
          #   File.join(Seek::Config.git_temporary_filestore_path, uuid)
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
          # def worktree_id
          #   "#{git_working_path} #{commit}"
          # end
          #
          # def worktree
          #   git_base.worktrees[worktree_id]
          # end
          #
          # def add_worktree
          #   git_base.worktree(git_working_path, commit).add
          # end
          #
          # def remove_worktree
          #   git_base.worktree(git_working_path, commit).remove
          # end

          def self.proxy_class
            const_get(proxy_class_name)
          end
        end

        # The proxy object that will behave like the resource, but using attributes stored in the GitVersion.
        const_set(proxy_class_name, Class.new(::ResourceProxy))
        proxy_class.class_eval(&extension) if block_given?
      end
    end
  end
end
