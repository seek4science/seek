# Helper code to remove annoying CACHE (0.0ms) messages from active logger.
# Based on http://heliom.ca/blog/posts/disable-rails-cache-logging

# Implementation of logger that ignores messages containing forbidden words
# here “CACHE” and "Settings Load"
class CacheFreeLogger < ActiveSupport::TaggedLogging

  @@excluded = ['Settings Load','CACHE']

  def add(severity, message = nil, progname = nil, &block)
    if message.nil?
      if block_given?
        message = block.call
      else
        message = progname
        progname = nil #No instance variable for this like Logger
      end
    end
    if severity > Logger::DEBUG ||  !(@@excluded.map{|e| message.include? e}.include?(true))
        @logger.add(severity, "#{tags_text}#{message}", progname)
    end
  end
end

#Replace the existing logger with the filtering one
ActiveRecord::Base.logger = CacheFreeLogger.new(ActiveRecord::Base.logger) if Rails.env.development?
