module Git
  # A class to wrap ruby-git operations, in order to make testing easier.
  # Maybe we can remove this at some point if we figure out how to make git operations use VCR.
  class Base < SimpleDelegator
    def initialize(path)
      @git_base = Rugged::Repository.new(path)
      super(@git_base)
    end

    def base
      @git_base
    end

    def add_remote(name, url)
      @git_base.remotes.create(name, url)
    end

    def self.base_class
      self
    end

    def self.init(path)
      ::Rugged::Repository.init_at(path)
    end
  end
end