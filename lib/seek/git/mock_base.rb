module Seek
  module Git
    # A class to mock git operations for testing
    class MockBase < Base
      def revparse(rev)
        super(rev)
      rescue ::Git::GitExecuteError
        'abcdef12345'
      end

      def fetch

      end
    end
  end
end