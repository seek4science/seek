module Seek
  module Rdf
    module RdfStorage
      def save_rdf
        #seperate public and private (to an outside user) into separate directories
        if self.can_view?(nil)
          path = public_rdf_storage_path
          other_path = private_rdf_storage_path
        else
          path = private_rdf_storage_path
          other_path = public_rdf_storage_path
        end

        #this is necessary to remove the old rdf if the permissions switched from public to private, or vice-versa
        FileUtils.rm other_path if File.exists?(other_path)

        #need to get the rdf first, before creating the file
        rdf = self.to_rdf

        File.open(path,"w") do |f|
          f.write(rdf)
          f.flush
        end
        path
      end

      def delete_rdf
        public_path = public_rdf_storage_path
        private_path = private_rdf_storage_path
        FileUtils.rm(public_path) if File.exists?(public_path)
        FileUtils.rm(private_path) if File.exists?(private_path)
      end

      def private_rdf_storage_path
        rdf_storage_path "private"
      end

      def public_rdf_storage_path
        rdf_storage_path "public"
      end

      def rdf_storage_path inner_dir=nil?
        inner_dir ||= self.can_view?(nil) ? "public" : "private"
        path = File.join(Seek::Config.rdf_filestore_path,inner_dir)
        if !File.exists?(path)
          FileUtils.mkdir_p(path)
        end
        unique_id="#{self.class.name}-#{self.id}"
        filename = "#{unique_id}.rdf"
        File.join(path,filename)
      end
    end
  end
end