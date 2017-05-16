module Seek
  module Openbis
    # General behaviour for an entity in openBIS. Specific entities are defined as specialized subclasses
    class Entity
      attr_reader :json, :modifier, :registration_date, :modification_date, :code,
                  :perm_id, :registrator, :openbis_endpoint, :exception

      def ==(other)
        perm_id == other.perm_id
      end

      def initialize(openbis_endpoint, perm_id = nil)
        @openbis_endpoint = openbis_endpoint
        unless @openbis_endpoint && @openbis_endpoint.is_a?(OpenbisEndpoint)
          raise 'OpenbisEndpoint expected and required'
        end

        if perm_id
          begin
            json = query_application_server_by_perm_id(perm_id)
            unless json[json_key]
              raise Seek::Openbis::EntityNotFoundException, "Unable to find #{type_name} with perm id #{perm_id}"
            end
            populate_from_json(json[json_key].first)
          rescue Fairdom::OpenbisApi::OpenbisQueryException => e
            @exception = e
          end
        end
      end

      def populate_from_json(json)
        @json = json
        @modifier = json['modifier']
        @code = json['code']
        @perm_id = json['permId']
        @registrator = json['registerator']
        @registration_date = DateTime.parse(json['registrationDate'])
        @modification_date = DateTime.parse(json['modificationDate'])
        self
      end

      def all
        json = query_application_server_by_perm_id
        construct_from_json(json)
      end

      def construct_from_json(json)
        return [] unless json[json_key]
        json[json_key].collect do |element|
          self.class.new(openbis_endpoint).populate_from_json(element)
        end.sort_by(&:modification_date).reverse
      end

      def find_by_perm_ids(perm_ids)
        # insert a dummy id if empty, otherwise a blank query occurs which returns everything
        perm_ids << 'xxx222111sddd-dummy' if perm_ids.empty?
        ids_str = perm_ids.compact.uniq.join(',')
        json = query_application_server_by_perm_id(ids_str)
        construct_from_json(json)
      end

      def comment
        properties['COMMENT'] || ''
      end

      def cache_key(perm_id)
        "#{type_name}/#{Digest::SHA2.hexdigest(perm_id)}"
      end

      def samples
        unless @samples
          @samples = Seek::Openbis::Zample.find_by_perm_ids(sample_ids)
        end
        @samples
      end

      def datasets
        @datasets ||= Seek::Openbis::Dataset.new(openbis_endpoint).find_by_perm_ids(dataset_ids)
      end

      # provides the number of datasets without having to fetch and construct as you would with datasets.count
      def dataset_count
        dataset_ids.count
      end

      def error_occurred?
        !exception.nil?
      end

      protected

      def json_key
        type_name.downcase.pluralize
      end

      private

      def query_application_server_by_perm_id(perm_id = '')
        cached_query_by_perm_id(perm_id) do
          application_server_query_instance.query(entityType: type_name, queryType: 'ATTRIBUTE',
                                                  attribute: 'PermID', attributeValue: perm_id)
        end
      end

      def query_datastore_server_by_dataset_perm_id(perm_id = '')
        cached_query_by_perm_id(perm_id) do
          datastore_server_query_instance.query(entityType: type_name, queryType: 'ATTRIBUTE',
                                                attribute: 'DataSetPermID', attributeValue: perm_id)
        end
      end

      def cached_query_by_perm_id(perm_id)
        raise 'Block required for doing query' unless block_given?
        key = cache_key(perm_id)
        Rails.logger.info("CACHE KEY = #{key}")
        openbis_endpoint.metadata_store.fetch(key) do
          Rails.logger.info("NO CACHE, FETCHING FROM SERVER #{perm_id}")
          yield
        end
      end

      def application_server_query_instance
        Fairdom::OpenbisApi::ApplicationServerQuery.new(openbis_endpoint.as_endpoint, openbis_endpoint.session_token)
      end

      def datastore_server_query_instance
        Fairdom::OpenbisApi::DataStoreQuery.new(openbis_endpoint.dss_endpoint, openbis_endpoint.session_token)
      end

      def datastore_server_download_instance
        Fairdom::OpenbisApi::DataStoreDownload.new(openbis_endpoint.dss_endpoint, openbis_endpoint.session_token)
      end

      def dataset_ids
        json['datasets']
      end
    end
  end
end
