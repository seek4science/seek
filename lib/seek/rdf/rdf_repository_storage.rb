module Seek
  module Rdf
    # Module that works in conjuction with RdfStorage to support maintaning the RDF in a triple store as well as those stored on
    # file
    module RdfRepositoryStorage
      include RdfFileStorage
      # Will send the rdf related to self to the configured repository. This will not remove previously existing triples.
      # It will also updated the saved file containing the latest rdf
      def send_rdf_to_repository
        Seek::Rdf::RdfRepository.instance.send_rdf(self)
      end

      # will remove the rdf triples that were previously sent the the repository and stored in the rdf file for self.
      # it will also remove the saved file containing the rdf
      def remove_rdf_from_repository
        Seek::Rdf::RdfRepository.instance.remove_rdf(self)
      end

      # updates the repository with the changes for self, consolidating the differences between now and when the last rdf
      # was created, and only replacing those that have changed.
      # It will also update the saved file containing the rdf
      def update_repository_rdf
        Seek::Rdf::RdfRepository.instance.update_rdf(self)
      end

      # checks that a repository is available and that is has been configured for the current Rails.env
      def rdf_repository_configured?
        !Seek::Rdf::RdfRepository.instance.nil? && Seek::Rdf::RdfRepository.instance.configured?
      end

      # returns any active-record items that are linked to this item, as determined by querying the repository. These can
      # be subject or object items, where this item is the object or subject respectively.
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
            rescue Exception => e
              puts e
            end
          end
        end
        items
      end
    end
  end
end
