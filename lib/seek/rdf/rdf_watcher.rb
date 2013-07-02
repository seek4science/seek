#watches for changed files in the rdf file path locations.
#this class needs to be extended with a subclass to push to the rdf to the appropriate RDF store
#in the subclass the methods that need implementing are updated, created, deleted

require 'fssm'

module Seek
  module Rdf
    class RdfWatcher
      attr_accessor :args

      def initialize *args
        @args = args
        setup_logger
      end

      #triggered when an rdf file has been updated, this should be overridden in the subclass
      #the is_private flag indicates that the rdf is in the private subfolder, and is rdf for an entity that is not publicly visible
      def updated path,is_private
        @logger.info "Something changed the file '#{path}' - is_private=#{is_private}"
      end

      #triggered when an rdf file has been created, this should be overridden in the subclass
      #the is_private flag indicates that the rdf is in the private subfolder, and is rdf for an entity that is not publicly visible
      def created path,is_private
        @logger.info "Something created the file '#{path}' - is_private=#{is_private}"
      end

      #triggered when an rdf file has been deleted, this should be overridden in the subclass
      #the is_private flag indicates that the rdf is in the private subfolder, and is rdf for an entity that is not publicly visible
      def deleted path,is_private
        @logger.info "Something deleted the file '#{path}' - is_private=#{is_private}"
      end

      def start
        start_up
      end

      private

      def start_up

        path = rdf_filestore_path

        at_exit do
          @logger.info "Stopped watching *.rdf files in #{path}"
        end
        @logger.info "Started to watching *.rdf files in #{path}"

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

      def is_private? relative_path
        #play safe and say its private unless the root folder is public (rather than the less safe checking the root folder is 'private')
        File.split(relative_path)[0]!="public"
      end

      def rdf_filestore_path
        path = Seek::Config.rdf_filestore_path
        unless File.exists?(path)
          FileUtils.mkdir_p(path)
        end
        path
      end

      def setup_logger
        @logger = Logger.new File.join(Rails.root,"log","watch_rdf.log")
      end

    end
  end
end
