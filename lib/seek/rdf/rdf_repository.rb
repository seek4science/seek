module Seek
  module Rdf
    class RdfRepository

        def self.instance
          #TODO: in the future, when/if we support more repository flavours, the instance we return will need to be configurable
          Seek::Rdf::VirtuosoRepository.instance
        end

        def query
          get_query_object
        end

        def select *args
          get_repository_object.select *args
        end

        def insert *args
          get_repository_object.insert *args
        end

        def delete *args
          get_repository_object.delete *args
        end

        def send_rdf(item)
          if configured?
            connect_to_repository
            graphs = rdf_graph_uris(item)
            with_statements(item) do |statement|
              if statement.valid?
                graphs.each do |graph_uri|
                  send_statement_to_repository statement, graph_uri
                end
              else
                Rails.logger.error("Invalid statement - '#{statement}'")
              end
            end
          else
            Rails.logger.warn "Attempting to send rdf, but not configured"
          end
        end

        def remove_rdf(item)
          if configured?
            connect_to_repository
            private_path = item.private_rdf_storage_path
            graph = get_configuration.private_graph
            if !graph.nil? && File.exist?(private_path)
              with_statements_from_file private_path do |statement|
                if statement.valid?
                  remove_statement_from_repository statement,graph
                end
              end
            end
            public_path = item.public_rdf_storage_path
            graph = get_configuration.private_graph
            if !graph.nil? && File.exist?(public_path)
              with_statements_from_file public_path do |statement|
                if statement.valid?
                  remove_statement_from_repository statement,graph
                end
              end
            end
          end
        end

        def configured?
          File.exists?(config_path) && enabled_for_environment?
        end

        #Abstract methods

        def get_configuration
          raise "Not implemented: subclass should provide a configuration class"
        end

        def get_query_object
          raise "Not implemented: subclass should provide a suitable RDF::Query class"
        end

        def get_repository_object
          raise "Not implemented: subclass should provide a suitable instance of RDF::Repository"
        end

        private

        #Private abstract methods

        def config_filename
          raise "Not implemented: subclass should provide the name (not path) of the configuration filename"
        end

        def enabled_for_environment?
          raise "Not implemented: subclass should determine whether a configuration has been set for the current Rails.env"
        end


        def send_statement_to_repository statement, graph_uri
          graph = RDF::URI.new graph_uri
          q = query.insert([statement.subject, statement.predicate, statement.object]).graph(graph)
          result = insert(q)
          Rails.logger.debug(result)
        end

        def remove_statement_from_repository statement, graph_uri
          graph = RDF::URI.new graph_uri
          q = query.delete([statement.subject, statement.predicate, statement.object]).graph(graph)
          result = delete(q)
          Rails.logger.debug(result)
        end


        def rdf_graph_uris(item)
          if item.can_view?(nil)
            [get_configuration.public_graph,get_configuration.private_graph]
          else
            [get_configuration.private_graph]
          end.compact
        end

        def with_statements item, &block
          RDF::Reader.for(:rdfxml).new(item.to_rdf) do |reader|
            reader.each_statement do |statement|
              block.call(statement)
            end
          end
        end

        def with_statements_from_file path, &block
          RDF::Reader.for(:rdfxml).open(path) do |reader|
            reader.each_statement do |statement|
              Rails.logger.debug "Statement from #{path}- #{statement}"
              block.call(statement)
            end
          end
        end

        def config_path
          File.join(Rails.root,"config",config_filename)
        end

      end
  end
end