module Seek
  module Rdf
    module RdfRepositoryStorage

      def send_rdf_to_repository
        Seek::Rdf::RdfRepository.instance.send_rdf(self)
      end

      def remove_rdf_from_repository
        Seek::Rdf::RdfRepository.instance.remove_rdf(self)
      end

      def configured_for_rdf_send?
        !Seek::Rdf::RdfRepository.instance.nil? && Seek::Rdf::RdfRepository.instance.configured?
      end

    end
  end
end