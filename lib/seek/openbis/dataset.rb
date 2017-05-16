module Seek
  module Openbis
    # Represents an openBIS DataSet entity
    class Dataset < Entity
      attr_reader :dataset_type, :experiment_id, :sample_ids, :properties

      def populate_from_json(json)
        @properties = json['properties']
        @properties.delete_if { |key, _value| key == '@type' }
        @dataset_type = json['dataset_type']
        @experiment_id = json['experiment']
        @sample_ids = json['samples'].last
        super(json)
      end

      def dataset_type_text
        txt = dataset_type_description
        txt = dataset_type_code if txt.blank?
        txt
      end

      def dataset_type_description
        dataset_type['description']
      end

      def dataset_type_code
        dataset_type['code']
      end

      def dataset_files
        @dataset_files ||= Seek::Openbis::DatasetFile.new(openbis_endpoint).find_by_dataset_perm_id(perm_id)
      end

      def dataset_files_no_directories
        dataset_files.reject(&:is_directory)
      end

      # FIMXE: we can speed things up and get this directly from the first API call rather than
      #   fetching the datasets, only getting the datasets on demand
      def dataset_file_count
        dataset_files_no_directories.count
      end

      def size
        dataset_files_no_directories.sum(&:size)
      end

      def type_name
        'DataSet'
      end

      def download(dest_folder, zip_path, root_folder)
        Rails.logger.info("Downloading folders for #{perm_id} to #{dest_folder}")
        datastore_server_download_instance.download(downloadType: 'dataset',
                                                    permID: perm_id,
                                                    source: '', dest: dest_folder)

        if File.exist?(zip_path)
          Rails.logger.info("Deleting old zip file #{zip_path}")
          FileUtils.rm(zip_path)
        end

        Rails.logger.info("Creating zip file #{zip_path}")
        Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
          Dir.glob("#{dest_folder}/**/*").reject { |f| File.directory?(f) }.each do |path|
            file_path_in_zip = File.join(root_folder, Pathname(path).relative_path_from(Pathname(dest_folder)).to_s)
            Rails.logger.info("Adding #{path} as #{file_path_in_zip} to zip file #{zip_path}")
            zipfile.add(file_path_in_zip, path)
          end
        end
        Rails.logger.info("Zip file #{zip_path} created")
        FileUtils.rm_rf(dest_folder)
        Rails.logger.info("Deleting #{dest_folder}")
      end

      def create_seek_datafile
        raise 'Already registered' if registered?
        df = DataFile.new(projects: [openbis_endpoint.project], title: "OpenBIS #{perm_id}",
                          license: openbis_endpoint.project.default_license)
        if df.save
          df.content_blob = ContentBlob.create(url: content_blob_uri, make_local_copy: false,
                                               external_link: false, original_filename: "openbis-#{perm_id}")
        end
        df
      end

      def registered?
        ContentBlob.where(url: content_blob_uri).any?
      end

      private

      def content_blob_uri
        "openbis:#{openbis_endpoint.id}:dataset:#{perm_id}"
      end
    end
  end
end
