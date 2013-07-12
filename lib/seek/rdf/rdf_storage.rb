module Seek
  module Rdf
    module RdfStorage
      include RdfRepositoryStorage
      def save_rdf
        delete_rdf
        path = self.rdf_storage_path

        File.open(path,"w") do |f|
          f.write(self.to_rdf)
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

        filename = rdf_storage_filename
        File.join(path,filename)
      end

      def rdf_storage_filename
        "#{self.class.name}-#{Rails.env}-#{self.id}.rdf"
      end
    end
  end
end