module Seek
  module Openbis
    # Represents an openBIS DataSet file entity
    class DatasetFile < Entity
      attr_accessor :path, :size, :is_directory, :dataset_perm_id, :file_perm_id

      def find_by_dataset_perm_id(perm_id)
        json = query_datastore_server_by_dataset_perm_id(perm_id)
        construct_from_json(json)
      end

      def filename
        path.split('/').last
      end

      def all
        json = query_datastore_server_by_perm_id
        construct_from_json(json)
      end

      def populate_from_json(json)
        @path = json['path']
        @dataset_perm_id = json['dataset']
        @file_perm_id = json['filePermId']
        @is_directory = json['isDirectory']
        @size = json['fileLength']
        self
      end

      def populate_from_perm_id(perm_id)
        json = query_datastore_server_by_perm_id(perm_id)
        populate_from_json(json[json_key][1])
      end

      def construct_from_json(json)
        super.sort_by(&:path)
      end

      def download(dest)
        datastore_server_download_instance.download(downloadType: 'file', permID: dataset_perm_id,
                                                    source: path, dest: dest)
      end

      def type_name
        'DataSetFile'
      end
    end
  end
end
