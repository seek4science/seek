require 'yaml'


class Version
  include Comparable

  attr_accessor :major, :minor, :patch, :milestone, :build, :branch, :committer, :build_date

  # Creates a new instance of the Version class using information in the passed
  # Hash to construct the version number.
  #
  #   Version.new(:major => 1, :minor => 0) #=> "1.0"
  def initialize(args = nil)
    if args && args.is_a?(Hash)
      args.each_key {|key| args[key.to_sym] = args.delete(key) unless key.is_a?(Symbol)}
  
      [:major, :minor].each do |param|
        raise ArgumentError.new("The #{param.to_s} parameter is required") if args[param].nil?
      end

      @major = int_value(args[:major])
      @minor = int_value(args[:minor])

      if args[:patch] && args[:patch] != '' && int_value(args[:patch]) >= 0
        @patch = int_value(args[:patch])
      end
      
      if args[:milestone] && args[:milestone] != '' && int_value(args[:milestone]) >= 0
        @milestone = int_value(args[:milestone])
      end

      if args[:build] && args[:build] != '' && int_value(args[:build]) >= 0
        @build = int_value(args[:build])
      end

      @branch = args[:branch] unless args[:branch] == ''
      @committer = args[:committer] unless args[:committer] == ''
      
      if args[:build_date] && args[:build_date] != ''
        str = args[:build_date].to_s
        @build_date = Date.parse(str)
      end

      @build = case args[:build] 
               when 'svn'
                 get_build_from_subversion
               when 'git-revcount'
                 get_revcount_from_git
               when 'git-hash'
                 get_hash_from_git
               else
                 args[:build] && int_value(args[:build])
               end
    end
  end

  # Parses a version string to create an instance of the Version class.
  def self.parse(version)
    m = version.match(/(\d+)\.(\d+)(?:\.(\d+))?(?:\sM(\d+))?(?:\s\((\d+)\))?(?:\sof\s(\w+))?(?:\sby\s(\w+))?(?:\son\s(\S+))?/)

    raise ArgumentError.new("The version '#{version}' is unparsable") if m.nil?

    version = Version.new :major => m[1],
								:minor         => m[2],
								:patch         => m[3],
								:milestone     => m[4],
								:build         => m[5],
								:branch        => m[6],
								:committer     => m[7]

		if (m[8] && m[8] != '')
		  date = Date.parse(m[8])
		  version.build_date = date
	  end
    
		return version						
  end

  # Loads the version information from a YAML file.
  def self.load(path)
    Version.new YAML::load(File.open(path))
  end

  def <=>(other)
    # if !self.build.nil? && !other.build.nil?
    #   return self.build <=> other.build
    # end

    %w(build major minor patch milestone branch committer build_date).each do |meth|
      rhs = self.send(meth) || -1 
      lhs = other.send(meth) || -1

      ret = lhs <=> rhs
      return ret unless ret == 0
    end

    return 0
  end

  def to_s
    str = "#{major}.#{minor}" 
    str << ".#{patch}" unless patch.nil?
    str << " M#{milestone}" unless milestone.nil?
    str << " (#{build})" unless build.nil?
    str << " of #{branch}" unless branch.nil?
    str << " by #{committer}" unless committer.nil?
    str << " on #{build_date}" unless build_date.nil?

    str
  end

private

  def get_build_from_subversion
    if File.exists?(".svn")
      #YAML.parse(`svn info`)['Revision'].value
      match = /(?:\d+:)?(\d+)M?S?/.match(`svnversion . -c`)
      match && match[1]
    end
  end

  def get_revcount_from_git
    if File.exists?(".git")
      `git rev-list HEAD|wc -l`.strip
    end
  end

  def get_hash_from_git
    if File.exists?(".git")
      `git show --pretty=format:%H|head -n1|cut -c 1-6`.strip
    end
  end

  def int_value(value)
    value.to_i.abs
  end
  
end

if defined?(RAILS_ROOT) && File.exists?("#{RAILS_ROOT}/config/version.yml")
  APP_VERSION = Version.load "#{RAILS_ROOT}/config/version.yml"
end
