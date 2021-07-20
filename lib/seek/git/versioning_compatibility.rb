# An adapter to allow switching between git versioning and the original explicit versioning.
module Seek
  module Git
    module VersioningCompatibility
      def latest_version
        is_git_versioned? ? latest_git_version : super
      end

      def visible_versions(user = User.current_user)
        is_git_versioned? ? visible_git_versions(user) : super
      end

      def find_version(version)
        is_git_versioned? ? find_git_version(version) : super
      end

      def describe_version(version_number)
        vs = all_versions

        return '(earliest)' if version_number == vs.first.version
        return '(latest)' if version_number == vs.last.version
        ''
      end

      def all_versions
        is_git_versioned? ? git_versions : versions
      end
    end
  end
end