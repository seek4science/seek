module Seek
  module Git
    # A class to wrap ruby-git operations, in order to make testing easier.
    class Base
      delegate :config, :revparse, :object, :gtree, :add, :add_remote,
               :remotes, :fetch, :checkout, :commit, :with_temp_working, to: :@git_base

      def initialize(git_base)
        @git_base = git_base
      end

      def self.base_class
        Rails.env.test? ? Seek::Git::MockBase : self
      end
    end
  end
end