#watches for changed files in the rdf file path locations.
#this class needs to be extended with a subclass to push to the rdf to the appropriate RDF store

require 'fssm'

module Seek
  module Rdf
    class RdfWatcher
      attr_accessor :args

      def initialize *args
        @args = args
      end

      def updated path,is_private
        puts "Someone changed the file '#{path}' - is_private=#{is_private}"
      end

      def created path,is_private
        puts "Someone created the file '#{path}' - is_private=#{is_private}"
      end

      def deleted path,is_private
        puts "Someone deleted the file '#{path}' - is_private=#{is_private}"
      end

      def daemonize
        path = rdf_filestore_path
        puts "Starting to watch #{path}"
        FSSM.monitor(path,"**/*.rdf") do |path|

          path.update do |base, relative|
            updated File.join(base,relative),is_private?(relative)
          end

          path.create do |base, relative|
            created File.join(base,relative),is_private?(relative)
          end

          path.delete do |base, relative|
            deleted File.join(base,relative),is_private?(relative)
          end

        end
      end

      private

      def is_private? relative_path
        #play safe and say its private unless the root folder is public (rather than the less safe checking the root folder is 'private')
        File.split(relative_path)[0]!="public"
      end

      def rdf_filestore_path
        path = RdfGeneration.rdf_filestore_path
        unless File.exists?(path)
          FileUtils.mkdir_p(path)
        end
        path
      end

    end
  end
end
