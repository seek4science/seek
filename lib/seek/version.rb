module Seek
  class Version
    attr_reader :major, :minor, :patch

    def initialize(path)
      yml = YAML.safe_load(File.open(path))
      @major = yml['major']
      @minor = yml['minor']
      @patch = yml['patch']
    end

    def self.read(path = Rails.root.join('config/version.yml'))
      Seek::Version.new(path)
    end

    def self.read_cached(path = Rails.root.join('config/version.yml'))
      @@version ||= read(path)
    end

    def to_s
      v = "#{major}.#{minor}"
      v << ".#{patch}" if patch
      v
    end
  end
end
