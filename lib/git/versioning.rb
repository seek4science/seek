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
        self.git_version_class_name = options[:git_version_class_name] || 'Git::Version'

        class_eval do
          has_many :git_versions, as: :resource, dependent: :destroy, class_name: 'Git::Version'
          has_one :local_git_repository, as: :resource, class_name: 'Git::Repository'

          attr_accessor :git_version_attributes

          after_create :save_git_version_on_create, if: -> { Seek::Config.git_support_enabled }
          after_update :sync_resource_attributes

          def is_git_versioned?
            git_version&.git_repository&.persisted? || !@git_version_attributes.blank?
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
            self.git_version_attributes = nil
            version
          end

          def save_as_new_git_version(extra_git_version_attributes = {})
            extra_git_version_attributes.reverse_merge!(@git_version_attributes || {})
            version = self.git_versions.build(extra_git_version_attributes)
            version.resource_attributes = self.attributes
            version.save
            self.git_version_attributes = nil
            version
          end

          def sync_resource_attributes
            version = latest_git_version
            return unless version&.mutable?
            version.sync_resource_attributes
          end

          def initial_git_version
            @initial_git_version ||= self.git_versions.build(@git_version_attributes)
          end

          def visible_git_versions(user = User.current_user)
            scopes = [Seek::ExplicitVersioning::VISIBILITY_INV[:public]]
            scopes << Seek::ExplicitVersioning::VISIBILITY_INV[:registered_users] if user&.person&.member?
            scopes << Seek::ExplicitVersioning::VISIBILITY_INV[:private] if can_manage?(user)

            git_versions.where(visibility: scopes)
          end

          # def state_allows_download?(*args)
          #   latest_git_version.commit.present?
          # end

          def self.git_version_class
            const_get(git_version_class_name)
          end
        end

        names = git_version_class_name.split("::")
        klass = names.pop
        base = self
        names.each do |mod|
          base = base.const_set(mod, Module.new)
        end
        base.const_set(klass, Class.new(::Git::Version))
        git_version_class.class_eval(&extension) if block_given?
      end
    end
  end
end
