module Seek
  module Rdf
    module RdfRepository

      def remove_rdf_from_repository
        if configured_for_rdf_send?
          connect_to_repository
          private_path = self.private_rdf_storage_path
          graph = @config.private_graph
          if !graph.nil? && File.exist?(private_path)
            with_statements_from_file private_path do |statement|
              if statement.valid?
                remove_statement_from_repository statement,graph
              end
            end
          end
          public_path = self.public_rdf_storage_path
          graph = @config.private_graph
          if !graph.nil? && File.exist?(public_path)
            with_statements_from_file public_path do |statement|
              if statement.valid?
                remove_statement_from_repository statement,graph
              end
            end
          end
        end
      end

      def send_rdf_to_repository
        if configured_for_rdf_send?
          connect_to_repository
          graphs = rdf_graph_uris
          with_statements do |statement|
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

      def rdf_graph_uris
        if self.can_view?(nil)
          [@config.public_graph,@config.private_graph]
        else
          [@config.private_graph]
        end.compact
      end

      def with_statements &block
        RDF::Reader.for(:rdfxml).new(self.to_rdf) do |reader|
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

      def configured_for_rdf_send?
        File.exists?(rdf_repository_config_path)
      end

      def rdf_repository_config_path
        File.join(Rails.root,"config",rdf_repository_config_filename)
      end

    end
  end
end