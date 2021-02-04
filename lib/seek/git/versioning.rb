module Seek
  module Git
    module Versioning
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def git_versioning(options = {}, &extension)
          # don't allow multiple calls
          return if reflect_on_association(:git_versions)

          cattr_accessor :git_version_class_name
          self.git_version_class_name = options[:git_version_class_name]  || 'GitVersion'

          class_eval do
            has_many :git_versions, as: :resource, dependent: :destroy
            has_one :local_git_repository, as: :resource, class_name: 'GitRepository'
            delegate :git_base, :file_exists?, :file_contents, :object, :ref, :commit, :tree, :trees, :blobs, :in_dir, :in_temp_dir, to: :git_version

            attr_writer :git_version_attributes

            after_create :save_git_version_on_create

            def is_git_versioned?
              commit.present?
            end

            def git_version
              persisted? ? latest_git_version : initial_git_version
            end

            def find_git_version(version)
              git_versions.where(version: version).first
            end

            def latest_git_version
              git_versions.last
            end

            def save_git_version_on_create
              version = initial_git_version
              version.metadata = self.attributes
              version.save
            end

            def initial_git_version
              self.git_versions.build(git_version_attributes.merge(mutable: git_version_attributes[:remote].blank?))
            end

            def git_version_attributes
              (@git_version_attributes || {}).with_indifferent_access.slice(
                  :name, :description, :ref, :commit, :root_path, :git_repository_id, :git_annotations_attributes
              ).reverse_merge(default_git_version_attributes)
            end

            def default_git_version_attributes
              { name: "Version #{git_versions.count + 1}", ref: 'refs/heads/master' }
            end

            # def state_allows_download?(*args)
            #   latest_git_version.commit.present?
            # end

            def self.git_version_class
              const_get(git_version_class_name)
            end
          end

          const_set(git_version_class_name, Class.new(::GitVersion))
          git_version_class.class_eval(&extension) if block_given?
        end
      end
    end
  end
end
