# An adapter to allow switching between git versioning and the original explicit versioning.
module Git
  module VersioningCompatibility
    def latest_version
      is_git_versioned? ? latest_git_version : latest_standard_version
    end

    def previous_version(base = version)
      is_git_versioned? ? previous_git_version(base) : previous_standard_version(base)
    end

    def visible_versions(user = User.current_user)
      is_git_versioned? ? visible_git_versions(user) : visible_standard_versions(user)
    end

    def find_version(version)
      is_git_versioned? ? find_git_version(version) : find_standard_version(version)
    end

    def describe_version(version_number)
      vs = versions

      return '(earliest)' if version_number == vs.first.version
      return '(latest)' if version_number == vs.last.version
      ''
    end

    def versions
      is_git_versioned? ? git_versions : standard_versions
    end
  end
end