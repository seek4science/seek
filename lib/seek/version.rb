module Seek
  # Provides access to the version information stored in config/version.yml, or from an alternative path.
  # The yaml MUST provide the major and minor values, and optionally the patch
  class Version
    attr_reader :major, :minor, :patch

    def initialize(path)
      yml = YAML.safe_load(File.open(path))
      @major = yml['major']
      @minor = yml['minor']
      @patch = yml['patch']
    end

    # reads the YAML to create a Seek::Version instance
    def self.read(path = Rails.root.join('config/version.yml'))
      Seek::Version.new(path)
    end

    # reads the YAML and stores a copy of the Seek::Version, which is returned for subsequent calls
    def self.read_cached(path = Rails.root.join('config/version.yml'))
      @@version ||= read(path)
    end

    def self.git_version
      `git rev-parse HEAD`.chomp
    end

    def self.git_branch
      `git rev-parse --abbrev-ref HEAD`.chomp
    end

    def to_s
      v = "#{major}.#{minor}"
      v << ".#{patch}" if patch
      v
    end
  end
end
