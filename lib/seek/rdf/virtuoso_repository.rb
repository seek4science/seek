require 'rdf/virtuoso'
require 'rdf/rdfxml'

module Seek
  module Rdf
    # A specialization of RdfRepository, to support the Open Virtuoso Quad Store.
    class VirtuosoRepository < RdfRepository
      include Singleton

      class Config < Struct.new(:username, :password, :uri, :update_uri, :private_graph, :public_graph); end
      QUERY = RDF::Virtuoso::Query

      def get_query_object
        QUERY
      end

      def get_repository_object
        connect_to_repository if @repo.nil?
        @repo
      end

      def get_configuration
        read_configuration if @config.nil?
        @config
      end

      private

      def read_configuration
        if configured?
          @config = Config.new
          @config.username = yaml[Rails.env]['username']
          @config.password = yaml[Rails.env]['password']
          @config.uri = yaml[Rails.env]['uri']
          @config.update_uri = yaml[Rails.env]['update_uri']
          @config.private_graph = yaml[Rails.env]['private_graph']
          @config.public_graph = yaml[Rails.env]['public_graph']
        else
          raise Exception, "No configuration file found at #{config_path}"
        end
      end

      def connect_to_repository
        @repo = RDF::Virtuoso::Repository.new(get_configuration.uri,
                                              update_uri: get_configuration.update_uri,
                                              username: get_configuration.username,
                                              password: get_configuration.password,
                                              auth_method: 'digest')
      end

      def enabled_for_environment?
        !yaml[Rails.env].nil? && !yaml[Rails.env]['disabled']
      end

      def config_filename
        'virtuoso_settings.yml'
      end

      def yaml
        @yaml ||= YAML.safe_load(ERB.new(File.new(config_path).read).result)
      end
    end
  end
end
