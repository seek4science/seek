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

    # a stored copy of the version, which can be used to avoid repeated calls to read, and YAML loading
    APP_VERSION = read.freeze

    # returns the current version hash from git
    def self.git_version
      return '' unless git_present?
      `git rev-parse HEAD`.chomp
    end

    # returns the current git branch
    def self.git_branch
      return '' unless git_present?
      `git rev-parse --abbrev-ref HEAD`.chomp
    end

    # is git currently present to allow access to git information
    def self.git_present?
      File.exist?(Rails.root.join('.git'))
    end

    # equality check, based on the version string
    def ==(other)
      to_s == other.to_s
    end

    # converts to a string, as <major>.<minor>.<patch>
    def to_s
      v = "#{major}.#{minor}"
      v << ".#{patch}" if patch
      v
    end
  end
end
