module Licensee
  module Projects
    # Custom Project class because the default GitProject class does not allow Repos with `head_unborn?`, even though
    # it's OK in our case since we are passing an explicit revision.
    class GitVersionProject < ::Licensee::Projects::GitProject
      def initialize(git_version, detect_packages: false, detect_readme: false)
        @detect_packages = detect_packages
        @detect_readme = detect_readme
        @git_version = git_version
      end

      # The Rugged::Repository for the Git::Version
      def repository
        @git_version.git_repository.git_base.base
      end

      # The Rugged::Commit for the Git::Version
      def commit
        @git_version.commit_object
      end
    end
  end
end
