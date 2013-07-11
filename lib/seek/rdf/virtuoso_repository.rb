require 'rdf/virtuoso'
require 'rdf/rdfxml'

module Seek
  module Rdf
    module VirtuosoRepository
      include RdfRepository
      class Config < Struct.new(:username, :password, :uri, :update_uri, :private_graph, :public_graph); end
      QUERY = RDF::Virtuoso::Query


      def send_statement_to_repository statement, graph_uri
        graph = RDF::URI.new graph_uri
        q = QUERY.insert([statement.subject, statement.predicate, statement.object]).graph(graph)
        result = @repo.insert(q)
        Rails.logger.debug(result)
      end

      def remove_statement_from_repository statement, graph_uri
        graph = RDF::URI.new graph_uri
        q = QUERY.delete([statement.subject, statement.predicate, statement.object]).graph(graph)
        result = @repo.delete(q)
        Rails.logger.debug(result)
      end

      def get_query_object
        QUERY
      end


      def read_virtuoso_configuration

        if configured_for_rdf_send?
          y = YAML.load_file(rdf_repository_config_path)
          @config=Config.new
          @config.username=y[Rails.env]["username"]
          @config.password=y[Rails.env]["password"]
          @config.uri=y[Rails.env]["uri"]
          @config.update_uri=y[Rails.env]["update_uri"]
          @config.private_graph=y[Rails.env]["private_graph"]
          @config.public_graph=y[Rails.env]["public_graph"]

        else
          raise Exception.new "No configuration file found at #{rdf_repository_config_path}"
        end
      end

      def connect_to_repository
        read_virtuoso_configuration
        @repo =  RDF::Virtuoso::Repository.new(@config.uri,
                                               :update_uri => @config.update_uri,
                                               :username => @config.username,
                                               :password => @config.password,
                                               :auth_method => 'digest')
      end

      def enabled_for_environment?
        y = YAML.load_file(rdf_repository_config_path)
        !y[Rails.env].nil? && !y[Rails.env]["disabled"]
      end

      def rdf_repository_config_filename
        "virtuoso_settings.yml"
      end
    end
  end
end
