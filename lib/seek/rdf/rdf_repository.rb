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

      # Send the rdf related to item to the repository, and update the rdf file.
      #
      # The statements are written to the item's own named graph (see #item_graph_uri), which records exactly what
      # this item contributed, and to each of the aggregate graphs (public and/or private) that are queried.
      # The item graph also records which aggregate graphs it contributed to (<item graph> dcterms:isPartOf <graph>),
      # which #remove_rdf uses to avoid removing a statement that another item still asserts.
      #
      # Blank nodes are skolemized into IRIs so that the copies in the item graph and the aggregate graphs are the
      # same terms, and so they can be removed again.
      #
      # The statements are sent in a single update request, which Virtuoso applies as one transaction.
      def send_rdf(item, graphs = rdf_graph_uris(item), save_file = true)
        if configured? && item.rdf_supported?
          connect_to_repository
          execute_update(insert_item_operations(item, graphs))
          item.save_rdf_file if save_file
        else
          Rails.logger.warn 'Attempting to send rdf, but not configured'
        end
      end

      # Remove the rdf related to item from the repository, and delete the rdf file.
      #
      # Removes from each aggregate graph the statements recorded in the item's named graph, except for those that
      # another item graph contributing to the same aggregate graph also holds, then removes the item graph, in a single
      # update request.
      def remove_rdf(item, graphs = aggregate_graph_uris, delete_file = true)
        if configured? && item.rdf_supported?
          connect_to_repository
          execute_update(remove_item_operations(item, graphs))
          item.delete_rdf_file if delete_file
        end
      end

      # The named graph holding exactly the statements generated for item, along with the aggregate graphs it was
      # sent to. Kept within the namespace of the configured private graph so that environments sharing the same
      # store don't clash.
      def item_graph_uri(item)
        RDF::URI("#{get_configuration.private_graph}/items/#{item.class.name}/#{item.id}")
      end

      # Removes all of SEEK's statements from the repository, by dropping the aggregate graphs and every item graph.
      def clear_all
        return unless configured?

        connect_to_repository
        config = get_configuration
        graphs = item_graph_uris + [config.public_graph, config.private_graph].compact.map { |graph| RDF::URI(graph) }
        graphs.each do |graph|
          Rails.logger.debug(get_repository_object.drop("DROP SILENT GRAPH #{graph.to_base}"))
        end
      end

      # The named graphs of all the items in the repository (see #item_graph_uri)
      def item_graph_uris
        prefix = "#{get_configuration.private_graph}/items/"
        select(<<~SPARQL).map { |result| result[:g] }
          SELECT DISTINCT ?g WHERE { GRAPH ?g { ?s ?p ?o } FILTER(STRSTARTS(STR(?g), #{RDF::Literal(prefix).to_base})) }
        SPARQL
      end

      # Replaces the item's rdf in the repository, and updates the rdf file.
      #
      # The removal of the old statements (from all the aggregate graphs, in case the item's visibility changed) and
      # the insertion of the new ones are sent as a single update request, which Virtuoso applies as one transaction,
      # so a query never sees the item partly updated.
      def update_rdf(item)
        if configured? && item.rdf_supported?
          connect_to_repository
          execute_update(remove_item_operations(item, aggregate_graph_uris) +
                         insert_item_operations(item, rdf_graph_uris(item)))
          item.save_rdf_file
        end
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

      def aggregate_graph_uris
        [get_configuration.public_graph, get_configuration.private_graph].compact
      end

      # Sends the operations as one SPARQL update request
      def execute_update(operations)
        q = operations.join(" ;\n")
        Rails.logger.debug("Update SPARQL: #{q}")
        Rails.logger.debug(get_repository_object.update(q))
      end

      # Operations that insert the item's statements into its item graph, along with which aggregate graphs it is part
      # of, and then copy them from the item graph into each of those aggregate graphs.
      def insert_item_operations(item, graphs)
        item_graph = item_graph_uri(item)
        statements = skolemize(valid_statements(item))
        membership = graphs.map { |graph| RDF::Statement.new(item_graph, RDF::Vocab::DC.isPartOf, RDF::URI(graph)) }
        triples = (statements + membership).map { |statement| RDF::NTriples::Writer.serialize(statement) }.join

        ["INSERT DATA { GRAPH #{item_graph.to_base} {\n#{triples}} }"] + graphs.map do |graph|
          <<~SPARQL
            INSERT { GRAPH #{RDF::URI(graph).to_base} { ?s ?p ?o } }
            WHERE { GRAPH #{item_graph.to_base} { ?s ?p ?o } FILTER (?s != #{item_graph.to_base}) }
          SPARQL
        end
      end

      # Operations that remove the item's contribution from each of the graphs, and then remove its item graph.
      def remove_item_operations(item, graphs)
        item_graph = item_graph_uri(item)
        graphs.map { |graph| remove_item_contribution_query(item_graph, RDF::URI(graph)) } +
          ["DROP SILENT GRAPH #{item_graph.to_base}"]
      end

      # Deletes from graph the statements held in item_graph, unless another item graph that is part of graph also
      # holds them.
      def remove_item_contribution_query(item_graph, graph)
        is_part_of = RDF::Vocab::DC.isPartOf.to_base
        <<~SPARQL
          DELETE { GRAPH #{graph.to_base} { ?s ?p ?o } }
          WHERE {
            GRAPH #{item_graph.to_base} { ?s ?p ?o }
            GRAPH #{graph.to_base} { ?s ?p ?o }
            FILTER NOT EXISTS {
              GRAPH ?other { ?s ?p ?o . ?other #{is_part_of} #{graph.to_base} }
              FILTER (?other != #{item_graph.to_base})
            }
          }
        SPARQL
      end

      def valid_statements(item)
        item.to_rdf_graph.statements.select do |statement|
          statement.valid?.tap do |valid|
            Rails.logger.error("Invalid statement - '#{statement}'") unless valid
          end
        end
      end

      # Replaces blank nodes with skolem IRIs (https://www.w3.org/TR/rdf11-concepts/#section-skolemization), keeping
      # the same IRI for each occurrence of the same blank node.
      def skolemize(statements)
        skolem_iris = Hash.new do |hash, node|
          hash[node] = RDF::URI(Seek::Config.site_base_url.join(".well-known/genid/#{SecureRandom.uuid}").to_s)
        end
        statements.map do |statement|
          RDF::Statement.new(*statement.to_triple.map { |term| term.node? ? skolem_iris[term] : term })
        end
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
