module Seek
  module Doi
    class BaseException < RuntimeError
      def initialize(msg = 'A DOI exception occurred')
        super(msg)
      end

      def backtrace
        cause ? cause.backtrace : super
      end
    end

    class UnrecognizedTypeException < BaseException; end
    class FetchException < BaseException; end
    class ParseException < BaseException; end
    class MalformedDOIException < BaseException; end
    class NotFoundException < BaseException; end
    class RecordNotSupported < BaseException; end
    class RANotSupported < BaseException; end
  end
end
