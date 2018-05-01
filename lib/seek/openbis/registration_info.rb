module Seek
  module Openbis
    # container for passing status of registration of OpenBIS entities as SEEK objects
    class RegistrationInfo
      attr_reader :created, :issues, :primary, :assay, :study, :datafile
      def initialize(created = [], issues = [])
        @created = created || []
        @issues = issues || []
        @primary = nil
        @assay = nil
        @study = nil
        @datafile = nil
      end

      def assay=(obj)
        @assay = obj
        @primary = obj
        add_created obj
      end

      def study=(obj)
        @study = obj
        @primary = obj
        add_created obj
      end

      def datafile=(obj)
        @datafile = obj
        @primary = obj
        add_created obj
      end

      def add_issues(others)
        if others.is_a? Array
          @issues.concat others
        else
          @issues << others
        end
        self
      end

      def add_created(others)
        if others.is_a? Array
          @created.concat others
        else
          @created << others
        end
        self
      end

      def merge(other)
        add_created other.created
        add_issues other.issues
        self
      end
    end
  end
end
