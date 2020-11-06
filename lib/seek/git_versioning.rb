module Seek
  module GitVersioning
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def git_versioning(options = {}, &extension)
        # don't allow multiple calls
        return if reflect_on_association(:git_versions)

        cattr_accessor :git_versioned_class_name
        self.git_versioned_class_name = options[:class_name]  || 'GitVersion'

        class_eval do
          has_many :git_versions, class_name: "#{self}::#{git_versioned_class_name}", as: :resource, dependent: :destroy
          has_one :git_repository, as: :resource

          # before_create :set_new_version
          # after_create :save_version_on_create
          # after_update :sync_latest_version

          delegate :git_base, :file_contents, :object, :commit, :tree, :trees,:blobs, to: :latest_git_version

          def latest_git_version
            git_versions.last
          end
        end

        # create the dynamic versioned model
        const_set(git_versioned_class_name, Class.new(::GitVersion)).class_eval do
          # ...
        end

        versioned_class.class_eval(&extension) if block_given?
      end
    end
  end
end
