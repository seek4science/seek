require 'optparse'
require 'nailgun_config'
require 'ng_command'

module Nailgun
  class NailgunServer
    attr_accessor :args, :nailgun_options

    def initialize(args)
      raise ArgumentError, "please specify start|stop|-h" if args.empty?
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} start|stop"
        opts.on('-h', '--help', 'Show this message') do
          puts "Use: start to start server"
          puts "Use: stop to stop server"
          puts opts
          exit 1
        end
      end
      @args = opts.parse! args
    end

    def daemonize
      if @args.include? 'start'
        Nailgun::NgCommand.start_server
      elsif @args.include? 'stop'
        Nailgun::NgCommand.stop_server
      end
    end
  end
end
