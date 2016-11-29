module Seek
  module Openbis
    class DatasetFile < Entity

      File = Struct.new(:path, :name, :size, :is_directory, :dataset_id)
      attr_reader :files

      def find_by_perm_ids perm_ids
        ids_str=perm_ids.compact.uniq.join(",")
        json = query_datastore_server_by_perm_id(ids_str)
        construct_from_json(json)
      end

      def all
        json = query_datastore_server_by_perm_id
        construct_from_json(json)
      end

      def populate_from_json(json)
        @files = []
        json.each do |json_file|
          path=json_file["filePermId"]["filePath"]
          name=path.split('/').last
          dataset_id = json_file["filePermId"]["dataSetId"]["permId"]
          #TODO size in human readable format
          size = json_file["fileLength"].last
          is_directory = json_file["isDirectory"]

          @files << File.new(path,name,size,is_directory,dataset_id)
        end
        @files
      end

      def populate_from_perm_id perm_id
        json = query_datastore_server_by_perm_id(perm_id)
        populate_from_json(json[json_key][1])
      end

      def construct_from_json(json)
        self.class.new.populate_from_json(json[json_key][1])
      end

      def query_datastore_server_by_perm_id perm_id=""
        cache_key = "openbis-datastore-server-#{type_name}-#{Digest::SHA2.hexdigest(perm_id)}"
        Rails.cache.fetch(cache_key) do
          datastore_server_query_instance.query({:entityType => type_name, :queryType => "ATTRIBUTE", :attribute => "PermID", :attributeValue => perm_id})
        end
      end

      def download_by_perm_id type, perm_id, source, dest
        datastore_server_download_instance.download({:downloadType=>type,:permID=>perm_id,:source=>source,:dest=>dest})
      end

      def datastore_server_query_instance
        info = Seek::Openbis::ConnectionInfo.instance
        Fairdom::OpenbisApi::DataStoreQuery.new(info.dss_endpoint, info.session_token)
      end

      def datastore_server_download_instance
        info = Seek::Openbis::ConnectionInfo.instance
        Fairdom::OpenbisApi::DataStoreDownload.new(info.dss_endpoint, info.session_token)
      end

      def type_name
        'DataSetFile'
      end
    end
  end
end