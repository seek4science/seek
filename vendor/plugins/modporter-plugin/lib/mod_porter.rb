require 'strscan'

module ModPorter
  class InvalidSignature < StandardError
  end

  class UnknownError < StandardError
  end
  
  class UploadedFile
    attr_accessor :path, :content_type, :original_filename

    def initialize(options)
      @path = options[:path]
      @original_filename = options[:filename]
      @content_type = options[:content_type]
    end

    def to_tempfile
      return File.new(self.path)
    end

    def size
      File.size(self.path)
    end
  end
  
  module ClassMethods
    def porter_secret(val)
      self.mod_porter_secret = val
    end
  end

  module Filter
    def self.included(base)
      base.superclass_delegating_accessor :mod_porter_secret
      base.before_filter :normalize_mod_porters
      base.extend ModPorter::ClassMethods
    end

    def normalize_mod_porters
      x_uploads_header = request.headers["X-Uploads"] || request.headers["HTTP_X_UPLOADS"]
      return if x_uploads_header.blank?

      porter_params = x_uploads_header.split(",").uniq
      logger.info("Processing #{porter_params.inspect}")

      porter_params.each do |file_param|
        s = StringScanner.new(file_param)

        path = []
        path << s.scan(/\w+/).to_sym

        while !s.eos?
          if arr = s.scan(/\[\]/)
            path << [] # We have an array
          elsif key = s.scan(/\[(\w+)\]/)
            path << s[1].to_sym
          else
            raise ModPorter::UnknownError.new("Something went wrong when scaling the file uploads")
          end
        end

        last = path.pop

        h = path.inject(params) do |hash, value|
          if value.is_a?(Array)
            hash
          else
            hash[value]
          end
        end

        if last.is_a?(Array)
          h.map! do |e|
            check_signature!(e)
            UploadedFile.new(e)
          end
        else
          while h.is_a?(Array)
            h = h.first # WTF. file[][some1], file[][some2]. Maybe this work.
          end

          check_signature!(h[last])
          h[last] = UploadedFile.new(h[last])
        end
      end
    end

    def check_signature!(options)
      expected_digest = Digest::SHA1.digest("#{options[:path]}#{self.class.mod_porter_secret}")
      base64_encoded_digest = ActiveSupport::Base64.encode64(expected_digest).chomp
    
      if options[:signature] != base64_encoded_digest
        raise ModPorter::InvalidSignature.new("#{options[:signature]} != #{base64_encoded_digest}")
      end
    end
  end
end
