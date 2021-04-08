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

            attr_accessor :git_version_attributes

            after_create :save_git_version_on_create

            def is_git_versioned?
              git_version.present?
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
              return if @git_version_attributes.blank?
              version = initial_git_version
              version.resource_attributes = self.attributes
              version.save
            end

            def initial_git_version
              @initial_git_version ||= self.git_versions.build(@git_version_attributes)
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
