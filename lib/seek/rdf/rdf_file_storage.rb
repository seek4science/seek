module Seek
  module Rdf
    # provides methods related to storing Rdf, in particular in files, but also includes RdfRepositoryStorage to support
    # storage in a triple store if configured
    module RdfFileStorage
      # saves the RDF to a file according to the configured filestore, in a directory rdf/. Filenames are based upon the asset
      # type, the Rails.env, and the asset id. rdf for private asset (not publically visible) are stored in a private subdirectory,
      # and those that are public are stored in a public subdirectory
      def save_rdf_file
        delete_rdf_file
        path = rdf_storage_path

        File.open(path, 'w') do |f|
          f.write(to_rdf)
          f.flush
        end
        path
      end

      # deletes any files that contain the rdf for this item, either from public or private subdirectories.
      def delete_rdf_file
        public_path = public_rdf_storage_path
        private_path = private_rdf_storage_path
        FileUtils.rm(public_path) if File.exist?(public_path)
        FileUtils.rm(private_path) if File.exist?(private_path)
      end

      # returns the path that rdf for non publicly visible assets are stored.
      def private_rdf_storage_path
        rdf_storage_path 'private'
      end

      # returns the path that rdf for publicly visible assets are stored.
      def public_rdf_storage_path
        rdf_storage_path 'public'
      end

      # returns the path that rdf for this item will be stored, according to its visibility
      def rdf_storage_path(inner_dir = nil?)
        inner_dir ||= self.can_view?(nil) ? 'public' : 'private'
        path = File.join(Seek::Config.rdf_filestore_path, inner_dir)
        FileUtils.mkdir_p(path) unless File.exist?(path)

        filename = rdf_storage_filename
        File.join(path, filename)
      end

      # the generated filename for this asset, based upon its type, the Rails.env, and its id
      def rdf_storage_filename
        "#{self.class.name}-#{Rails.env}-#{id}.rdf"
      end
    end
  end
end
