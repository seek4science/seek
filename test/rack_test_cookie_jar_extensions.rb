# annoying workaround the shortcomings of Rack::Test::CookieJar
module Rack
  module Test
    class CookieJar
      attr_reader :permanent_called
      def permanent
        @permanent_called = true
        self
      end
    end
  end
end