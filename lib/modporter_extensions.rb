require 'mod_porter.rb'
module ModPorter
  class ActionController::Base
    include ModPorter::Filter
  end
  class UploadedFile
    def method_missing(method_name, *args, &block) #:nodoc:
      @tempfile = to_tempfile unless @tempfile
      @tempfile.__send__(method_name, *args, &block)
    end

    def respond_to? message
      super || (@tempfile ||= to_tempfile).respond_to?(message)
    end
  end
end