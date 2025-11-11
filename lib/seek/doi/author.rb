module Seek
  module Doi
    class Author

      # todo: add more fields if needed (e.g., affiliation, ORCID)
      # e.g.{"ORCID"=>"https://orcid.org/0000-0002-5263-5070", "authenticated-orcid"=>false, "given"=>"K. Jarrod", "family"=>"Millman", "sequence"=>"additional", "affiliation"=>[]}
      attr_accessor :first_name, :last_name

      def initialize(first_name:, last_name:)
        @first_name = first_name
        @last_name = last_name
      end

      def full_name
        [first_name, last_name].compact.join(' ')
      end
    end
  end
end
