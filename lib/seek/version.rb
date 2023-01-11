module Seek
  # Provides access to the version information stored in config/version.yml, or from an alternative path.
  # The yaml MUST provide the major and minor values, and optionally the patch
  class Version
    attr_reader :major, :minor, :patch

    GIT_VERSION_RECORD_FILE_PATH = Rails.root.join('config', '.git-revision')

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

    # returns the current version hash from git, or the file containing the record
    def self.git_version
      if git_version_record_present?
        File.read(GIT_VERSION_RECORD_FILE_PATH)
      elsif git_present?
        `git rev-parse HEAD`.chomp
      else
        ''
      end
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

    # is there a config/.git-revision file that contains the revision hash
    def self.git_version_record_present?
      File.exist?(GIT_VERSION_RECORD_FILE_PATH)
    end

    # equality check, based on the version string
    def ==(other)
      to_s == other.to_s
    end

    # converts to a string, as <major>.<minor>.<patch>
    def to_s
      "#{major}.#{minor}".tap { |v| v << ".#{patch}" if patch }
    end
  end
end
