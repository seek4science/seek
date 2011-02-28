module ModPorter
  class UploadedFile
    def method_missing(method_name, *args, &block) #:nodoc:
      @tempfile = to_tempfile unless @tempfile
      @tempfile.__send__(method_name, *args, &block)
    end
  end
end