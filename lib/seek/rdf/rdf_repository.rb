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

      # execute a SPARQL update request, which may hold several operations separated by ';'
      def update(*args)
        get_repository_object.update(*args)
      end

      # Sends the rdf related to item to the repository, and updates the rdf file.
      #
      # The statements are stored in the item's own named graph (see #item_graph_uri), and copied from there into each
      # of the given graphs. Which of those graphs the item contributed to is recorded in the item index graph (see
      # #item_index_graph_uri), so #remove_rdf can later remove exactly what was sent.
      def send_rdf(item, graphs = rdf_graph_uris(item), save_file = true)
        if configured? && item.rdf_supported?
          connect_to_repository
          execute_operations(send_operations(item, graphs))
          item.save_rdf_file if save_file
        else
          Rails.logger.warn 'Attempting to send rdf, but not configured'
        end
      end

      # Removes the rdf related to item from the repository, and deletes the rdf file.
      #
      # From each of the graphs the item contributed to, removes the statements in the item's named graph that no other
      # item's graph contributing to it still holds, and then drops the item's graph.
      def remove_rdf(item, graphs = aggregate_graph_uris, delete_file = true)
        if configured? && item.rdf_supported?
          connect_to_repository
          execute_operations(remove_operations(item, graphs))
          item.delete_rdf_file if delete_file
        end
      end

      # Replaces the rdf related to item in the repository, and updates the rdf file.
      #
      # The removal and the sending are made in a single update request. The store may apply its operations one at a
      # time, so if one fails the item can be left partly removed or sent; the next update repairs it, as the removal
      # works from what the item graph and index record rather than from the item's current rdf.
      def update_rdf(item)
        if configured? && item.rdf_supported?
          connect_to_repository
          execute_operations(remove_operations(item, aggregate_graph_uris) +
                             send_operations(item, rdf_graph_uris(item)))
          item.save_rdf_file
        end
      end

      # The named graph holding exactly the statements sent for item. It is within the namespace of #fullest_graph, so
      # that different SEEK instances sharing a store don't clash.
      def item_graph_uri(item)
        RDF::URI("#{item_graphs_prefix}#{item.class.base_class.name}/#{item.id}")
      end

      # The named graph recording, for each item graph, which of the public and private graphs it contributed to, as
      #   <item graph> dcterms:isPartOf <graph>
      def item_index_graph_uri
        RDF::URI(item_graphs_prefix.chomp('/'))
      end

      def configured?
        File.exist?(config_path) && enabled_for_environment?
      end

      # whether the endpoint is available and responds to requests, even if configured
      def available?
        select('ask where {?s ?p ?o}')
        true
      rescue StandardError => e
        Rails.logger.error("Error trying a simple query: #{e.message}")
        false
      end

      # provides the URI's of any items related to the item - discovered by querying the private graph, or the public
      # graph if there is no private graph, to find both:
      #  <this_item> ?predicate <related_item>
      # or
      # <related_item> ?predicate <this_item>
      def uris_of_items_related_to(item)
        graph = RDF::URI.new(fullest_graph)
        q = query.select.where([:s, :p, item.rdf_resource]).from(graph)
        results = select(q).collect { |result| result[:s] }

        q = query.select.where([item.rdf_resource, :p, :o]).from(graph)
        results |= select(q).collect { |result| result[:o] }

        results.select { |result| result.is_a?(RDF::URI) }.collect(&:to_s).uniq.reject do |uri|
          uri.start_with?(skolem_iri_prefix)
        end
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

      def aggregate_graph_uris
        [get_configuration.public_graph, get_configuration.private_graph].compact
      end

      # The private graph, which holds every item, or the public graph if there is no private graph
      def fullest_graph
        get_configuration.private_graph || get_configuration.public_graph
      end

      def item_graphs_prefix
        "#{fullest_graph}/items/"
      end

      def execute_operations(operations)
        return if operations.empty?

        request = operations.join(" ;\n")
        Rails.logger.debug("SPARQL update: #{request}")
        result = update(request)
        Rails.logger.debug(result)
      end

      # Operations that store the item's statements in its own graph, record which graphs it is part of, and then copy
      # its statements into each of those graphs. Nothing is stored if there are no graphs to send to, such as for a
      # private item when only a public graph is configured.
      def send_operations(item, graphs)
        return [] if graphs.empty?

        item_graph = item_graph_uri(item)
        part_of = graphs.map { |graph| RDF::Statement.new(item_graph, RDF::Vocab::DC.isPartOf, RDF::URI(graph)) }

        ["INSERT DATA {\n" \
         "  GRAPH #{item_graph.to_base} {\n#{ntriples(skolemize(valid_statements(item)))}  }\n" \
         "  GRAPH #{item_index_graph_uri.to_base} {\n#{ntriples(part_of)}  }\n" \
         '}'] +
          graphs.map do |graph|
            "INSERT { GRAPH #{RDF::URI(graph).to_base} { ?s ?p ?o } } " \
              "WHERE { GRAPH #{item_graph.to_base} { ?s ?p ?o } }"
          end
      end

      # Operations that remove the item's statements from each of the graphs it contributed to, and then drop the item's
      # graph and its index entry.
      def remove_operations(item, graphs)
        item_graph = item_graph_uri(item)
        graphs.map { |graph| remove_from_graph_operation(item_graph, RDF::URI(graph)) } +
          ["DELETE WHERE { GRAPH #{item_index_graph_uri.to_base} { #{item_graph.to_base} ?p ?o } }",
           "DROP SILENT GRAPH #{item_graph.to_base}"]
      end

      # Removes from graph the statements in item_graph, if item_graph is recorded as part of graph, unless another item
      # graph that is part of graph also holds them.
      def remove_from_graph_operation(item_graph, graph)
        index_graph = item_index_graph_uri.to_base
        part_of = RDF::Vocab::DC.isPartOf.to_base
        <<~SPARQL.chomp
          DELETE { GRAPH #{graph.to_base} { ?s ?p ?o } }
          WHERE {
            GRAPH #{index_graph} { #{item_graph.to_base} #{part_of} #{graph.to_base} }
            GRAPH #{item_graph.to_base} { ?s ?p ?o }
            FILTER NOT EXISTS {
              GRAPH #{index_graph} { ?other #{part_of} #{graph.to_base} }
              FILTER (?other != #{item_graph.to_base})
              GRAPH ?other { ?s ?p ?o }
            }
          }
        SPARQL
      end

      def valid_statements(item)
        item.to_rdf_graph.statements.select do |statement|
          statement.valid?.tap { |valid| Rails.logger.error("Invalid statement - '#{statement}'") unless valid }
        end
      end

      # Replaces each blank node with an IRI (https://www.w3.org/TR/rdf11-concepts/#section-skolemization), the same
      # IRI for every occurrence of the same blank node. A blank node can't be referred to in later requests, so would
      # otherwise be disconnected from the item and couldn't be removed.
      def skolemize(statements)
        iris = Hash.new do |hash, node|
          hash[node] = RDF::URI("#{skolem_iri_prefix}#{SecureRandom.uuid}")
        end
        statements.map do |statement|
          RDF::Statement.new(*statement.to_triple.map { |term| term.node? ? iris[term] : term })
        end
      end

      def skolem_iri_prefix
        Seek::Config.site_base_url.join('.well-known/genid/').to_s
      end

      def ntriples(statements)
        statements.map { |statement| "    #{RDF::NTriples::Writer.serialize(statement)}" }.join
      end

      def rdf_graph_uris(item)
        if item.can_view?(nil)
          [get_configuration.public_graph, get_configuration.private_graph]
        else
          [get_configuration.private_graph]
        end.compact
      end

      def config_path
        File.join(Rails.root, 'config', config_filename)
      end
      end
  end
end
