require 'thread'
require 'rubygems'
require 'rails/commands/server'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

# To listen on all ports by TZ
# module Rails
#  class Server
#    alias :default_options_bk :default_options
#    def default_options
#      default_options_bk.merge!(Host: '0.0.0.0')
#    end
#  end
# end
