module Seek
  module GitVersioning
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def git_versioning(options = {}, &extension)
        # don't allow multiple calls
        return if reflect_on_association(:git_versions)

        cattr_accessor :git_versioned_class_name, :proxy_class_name
        self.git_versioned_class_name = options[:class_name]  || 'GitVersion'
        self.proxy_class_name = options[:proxy_class_name]  || 'ResourceProxy'

        class_eval do
          has_many :git_versions, class_name: "#{self}::#{git_versioned_class_name}", as: :resource, dependent: :destroy
          has_one :git_repository, as: :resource

          # before_create :set_new_version
          # after_create :save_version_on_create
          # after_update :sync_latest_version

          delegate :git_base, :file_contents, :object, :commit, :tree, :trees, :blobs, to: :latest_git_version

          def latest_git_version
            git_versions.last
          end

          def git_working_path
            File.join(Seek::Config.git_temporary_filestore_path, uuid)
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

          def worktree_id
            "#{git_working_path} #{commit}"
          end

          def worktree
            git_base.worktrees[worktree_id]
          end

          def add_worktree
            git_base.worktree(git_working_path, commit).add
          end

          def remove_worktree
            git_base.worktree(git_working_path, commit).remove
          end

          def self.proxy_class
            const_get(proxy_class_name)
          end

          def self.git_versioned_class
            const_get(git_versioned_class_name)
          end
        end

        # create the dynamic versioned model
        const_set(git_versioned_class_name, Class.new(::GitVersion)).class_eval do
          def proxy
            resource.class.proxy_class.new(resource, self)
          end
        end

        const_set(proxy_class_name, Class.new(::ResourceProxy)).class_eval do
          # ...
        end

        proxy_class.class_eval(&extension) if block_given?
      end
    end
  end
end
