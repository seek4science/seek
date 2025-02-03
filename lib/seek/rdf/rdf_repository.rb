module Seek
  module Rdf
    # This is the base class of all rdf repositories, and can be considered an Abstract class. A subclass specialization
    # is required to support a given repository - an example of which is VirtuosoRepository.
    #
    # the base class must at least implement the methods
    #   get_configuration - supplies a configuration class
    #   get_query_object - supplies class for of Rdf::Query
    #   get_repository_object - supplies an instance of Rdf::Repository
    #
    #   config_filename - the filename (without the full path) of the configuration file, which will be found in config/
    #   enabled_for_environment? - indicates whether the repository has been configured for the given Rails.env
    #
    class RdfRepository
      # provides a singleton instance of the configured repository
      def self.instance
        # TODO: in the future, when/if we support more repository flavours, the instance we return will need to be configurable
        Seek::Rdf::VirtuosoRepository.instance
      end

      # an RDF::Query that can be used to create queries to query the repository
      def query
        get_query_object
      end

      # execute a selection query, which delegates to Rdf::Repository#query
      def select(*args)
        get_repository_object.select(*args)
      end

      # execute a insert query, which delegates to Rdf::Repository#query
      def insert(*args)
        get_repository_object.insert(*args)
      end

      # execute a deletion query, which delegates to Rdf::Repository#query
      def delete(*args)
        get_repository_object.delete(*args)
      end

      # send the rdf related to item to the repository, and update the rdf file
      def send_rdf(item, graphs = rdf_graph_uris(item), save_file = true)
        if configured? && item.rdf_supported?
          connect_to_repository
          Rails.logger.debug("RDF about to be sent for item: #{item.to_rdf}")
          with_statements(item) do |statement|
            if statement.valid?
              graphs.each do |graph_uri|
                send_statement_to_repository statement, graph_uri
              end
            else
              Rails.logger.error("Invalid statement - '#{statement}'")
            end
          end
          item.save_rdf_file if save_file
        else
          Rails.logger.warn 'Attempting to send rdf, but not configured'
        end
      end

      # remove the rdf related to item from the repository, and delete the rdf file
      def remove_rdf(item, graphs = [get_configuration.public_graph, get_configuration.private_graph].compact, delete_file = true)
        if configured? && item.rdf_supported?
          connect_to_repository
          graphs.each do |graph|
            q = query.delete([item.rdf_resource, :p, :o]).where([item.rdf_resource, :p, :o]).graph(RDF::URI(graph))
            Rails.logger.debug("Remove all SPARQL: #{q}")
            result = delete(q)
            Rails.logger.debug(result)
          end
          item.delete_rdf_file if delete_file
        end
      end

      # updates the rdf in the repository and updates the rdf file.
      def update_rdf(item)
        if configured? && item.rdf_supported?
          Rails.logger.debug("About to remove RDF for item #{item.inspect}")
          remove_rdf(item)
          Rails.logger.debug("About to add RDF for item #{item.inspect}")
          send_rdf(item)
        end
      end

      def configured?
        File.exist?(config_path) && enabled_for_environment?
      end

      # provides the URI's of any items related to the item - discovered by querying the triple store to find both:
      #  <this_item> ?predicate <related_item>
      # or
      # <related_item> ?predicate <this_item>
      def uris_of_items_related_to(item)
        q = query.select.where([:s, :p, item.rdf_resource]).from(RDF::URI.new(get_configuration.private_graph))
        results = select(q).collect { |result| result[:s] }

        q = query.select.where([item.rdf_resource, :p, :o]).from(RDF::URI.new(get_configuration.private_graph))
        results |= select(q).collect { |result| result[:o] }

        results.select { |result| result.is_a?(RDF::URI) }.collect(&:to_s).uniq
      end

      # Abstract methods

      def get_configuration
        raise 'Not implemented: subclass should provide a configuration class'
      end

      def get_query_object
        raise 'Not implemented: subclass should provide a suitable RDF::Query class'
      end

      def get_repository_object
        raise 'Not implemented: subclass should provide a suitable instance of RDF::Repository'
      end

      private

      # Private abstract methods

      def config_filename
        raise 'Not implemented: subclass should provide the name (not path) of the configuration filename'
      end

      def enabled_for_environment?
        raise 'Not implemented: subclass should determine whether a configuration has been set for the current Rails.env'
      end

      def last_rdf_file_path(item)
        path = nil
        path ||= item.rdf_storage_path if File.exist?(item.rdf_storage_path)
        path ||= item.private_rdf_storage_path if File.exist?(item.private_rdf_storage_path)
        path ||= item.public_rdf_storage_path if File.exist?(item.public_rdf_storage_path)
        path
      end

      def send_statement_to_repository(statement, graph_uri)
        Rails.logger.debug("sending statement #{statement} to graph #{graph_uri}")
        graph = RDF::URI.new graph_uri
        q = query.insert([statement.subject, statement.predicate, statement.object]).graph(graph)
        Rails.logger.debug("Insert statement SPARQL: #{q}")
        result = insert(q)
        Rails.logger.debug(result)
      end

      def rdf_graph_uris(item)
        if item.can_view?(nil)
          [get_configuration.public_graph, get_configuration.private_graph]
        else
          [get_configuration.private_graph]
        end.compact
      end

      def with_statements(item)
        RDF::Reader.for(:ttl).new(item.to_rdf) do |reader|
          reader.each_statement do |statement|
            yield(statement)
          end
        end
      end

      def config_path
        File.join(Rails.root, 'config', config_filename)
      end
      end
  end
end
