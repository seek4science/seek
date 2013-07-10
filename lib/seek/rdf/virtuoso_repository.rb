require 'rdf/virtuoso'
require 'rdf/rdfxml'

module Seek
  module Rdf
    module VirtuosoRepository
      class Config < Struct.new(:username, :password, :uri, :update_uri, :private_graph, :public_graph); end
      QUERY = RDF::Virtuoso::Query

      def insert_rdf path, graph_uri
        graph = RDF::URI.new graph_uri
        with_statements_from_file path do |statement|
          if statement.valid?
            q = QUERY.insert([statement.subject, statement.predicate, statement.object]).graph(graph)
            result = @repo.insert(q)
            @logger.debug(result)
          else
            @logger.warn("Invalid statement - '#{statement}' - in #{path}")
          end
        end
        @logger.info "Adding statements for #{path}"
      end

      def with_statements_from_file path, &block
        RDF::Reader.for(:rdfxml).open(path) do |reader|
          reader.each_statement do |statement|
            @logger.debug "Statement from #{path}- #{statement}"
            block.call(statement)
          end
        end
      end

      def read_virtuoso_configuration
        config_path=File.join(Rails.root,"config",virtuoso_config_filename)
        if File.exist?(config_path)
          y = YAML.load_file(config_path)

          @config=Config.new
          @config.username=y["username"]
          @config.password=y["password"]
          @config.uri=y["uri"]
          @config.update_uri=y["update_uri"]
          @config.private_graph=y["private_graph"]
          @config.public_graph=y["public_graph"]

        else
          raise Exception.new "No configuration file found at #{config_path}"
        end
      end

      def connect_to_repository
        @repo =  RDF::Virtuoso::Repository.new(@config.uri,
                                               :update_uri => @config.update_uri,
                                               :username => @config.username,
                                               :password => @config.password,
                                               :auth_method => 'digest')
      end

      def virtuoso_config_filename
        "virtuoso_settings.yml"
      end
    end
  end
end
