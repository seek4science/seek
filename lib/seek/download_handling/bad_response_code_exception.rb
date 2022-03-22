module Seek
  module DownloadHandling
    class BadResponseCodeException < RuntimeError
      attr_reader :code

      def initialize(message = nil, code: nil)
        super(message)
        @code = code
      end
    end
  end
end
