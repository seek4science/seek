module Seek
  module Git
    # A class to wrap ruby-git operations, in order to make testing easier.
    class Base
      delegate :config, :revparse, :object, :gtree, :add, :add_remote,
               :remotes, :fetch, :checkout, :commit, :with_temp_working, to: :@git_base

      def initialize(git_base)
        @git_base = ::Git.open(git_base)
      end

      def self.base_class
        Rails.env.test? ? Seek::Git::MockBase : self
      end

      def self.ls_remote(remote, ref = nil)
        ::Git.ls_remote(ref ? "#{remote} #{ref}" : remote)
      end

      def self.init(path)
        ::Git.init(path)
      end
    end
  end
end