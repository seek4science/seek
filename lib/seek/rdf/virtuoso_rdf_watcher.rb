

module Seek
  module Rdf
    class VirtuosoRdfWatcher < Seek::Rdf::RdfWatcher
      include Seek::Rdf::VirtuosoRepository

      def initialize *args
        super *args
        read_virtuoso_configuration
        connect_to_repository
      end

      def created path,is_private
        super path,is_private
        sleep(0.1)
        insert_public path unless is_private
        insert_private path
      end

      def insert_public path
        insert_rdf path, @config.public_graph
      end

      def insert_private path
        insert_rdf path, @config.private_graph
      end

      def logfile_name
        "virtuoso_watch_rdf.log"
      end

    end
  end
end