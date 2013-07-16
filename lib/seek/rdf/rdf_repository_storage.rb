module Seek
  module Rdf
    module RdfRepositoryStorage

      def send_rdf_to_repository
        Seek::Rdf::RdfRepository.instance.send_rdf(self)
      end

      def remove_rdf_from_repository
        Seek::Rdf::RdfRepository.instance.remove_rdf(self)
      end

      def update_repository_rdf
        Seek::Rdf::RdfRepository.instance.update_rdf(self)
      end

      def rdf_repository_configured?
        !Seek::Rdf::RdfRepository.instance.nil? && Seek::Rdf::RdfRepository.instance.configured?
      end

      def related_items_from_sparql
        items = []
        if rdf_repository_configured?
          Seek::Rdf::RdfRepository.instance.uris_of_items_related_to(self).each do |uri|
            begin
              puts uri
              route = SEEK::Application.routes.recognize_path(uri)
              puts route
              if !route.nil? && !route[:id].nil?
                klass = route[:controller].singularize.camelize.constantize
                puts klass
                id = route[:id]
                items << klass.find(id)
              end
            rescue Exception=>e
              puts e
            end
          end
        end
        items
      end

    end
  end
end