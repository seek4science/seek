module Seek
  module Openbis
    # General behaviour for an entity in openBIS. Specific entities are defined as specialized subclasses
    class Entity
      attr_reader :json, :modifier, :registration_date, :modification_date, :code,
                  :perm_id, :registrator, :openbis_endpoint, :properties

      # debug is with puts so it can be easily seen on tests screens
      DEBUG = Seek::Config.openbis_debug ? true : false

      def ==(other)
        perm_id == other.perm_id
      end

      def initialize(openbis_endpoint, perm_id = nil, refresh = false)
        unless openbis_endpoint && openbis_endpoint.is_a?(OpenbisEndpoint)
          raise 'OpenbisEndpoint expected and required' + "Got #{openbis_endpoint} #{openbis_endpoint.class}"
        end

        @openbis_endpoint = openbis_endpoint
        @properties = {}

        fetch_from_server(perm_id, refresh) if perm_id
      end

      def fetch_from_server(perm_id, refresh)
        return unless perm_id

        cache_option = refresh ? { force: true } : nil

        json = query_application_server_by_perm_id(perm_id, cache_option)
        check_json_response(json, perm_id)
        populate_from_json(json[json_key].first)
      end

      def check_json_response(json, perm_id)
        unless json[json_key]
          raise Seek::Openbis::EntityNotFoundException, "Unable to find #{type_name} with perm id #{perm_id}"
        end
        unless json[json_key].size == 1
          msg = "Unable to find #{type_name} with perm id #{perm_id}, got #{json[json_key].size} hits"
          raise Seek::Openbis::EntityNotFoundException, msg
        end
      end

      def populate_from_json(json)
        raise "Cannot Populates #{self.class} from empty json" if json.nil? || json.empty?
        # for development by TZ
        puts "Populates #{self.class} from json:" if DEBUG
        puts json if DEBUG
        puts '-----' if DEBUG
        @json = json
        @modifier = json['modifier']
        @code = json['code']
        @perm_id = json['permId']
        @registrator = json['registerator']
        @registration_date = DateTime.parse(json['registrationDate'])
        @modification_date = DateTime.parse(json['modificationDate'])
        self
      end

      def all(refresh = false)
        cache_option = refresh ? { force: true } : nil
        json = query_application_server_for_all(cache_option)
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

      def find_by_type_codes(codes, refresh = false)
        return [] if codes.empty?
        cache_option = refresh ? { force: true } : nil
        json = query_application_server_by_type_codes(codes, cache_option)
        construct_from_json(json)
      end

      def comment
        properties['COMMENT'] || ''
      end

      def vetted_properties
        vet_properties(properties)
      end

      def vet_properties(hash)
        return {} unless hash

        hash.reject do |k, v|
          next(true) if v.nil?
          next(true) if k.to_sym == :ANNOTATIONS_STATE
          next(true) if k.to_sym == :XMLCOMMENTS && !v.start_with?('<')
          false
        end
      end

      def cache_key(perm_id)
        "#{type_name}/#{Digest::SHA2.hexdigest(perm_id)}"
      end

      def samples
        @samples ||= Seek::Openbis::Zample.new(openbis_endpoint).find_by_perm_ids(sample_ids)
      end

      def datasets
        @datasets ||= Seek::Openbis::Dataset.new(openbis_endpoint).find_by_perm_ids(dataset_ids)
      end

      # provides the number of datasets without having to fetch and construct as you would with datasets.count
      def dataset_count
        dataset_ids.count
      end

      def registered?
        OpenbisExternalAsset.registered?(self)

        # ContentBlob.where(url: defined?(content_blob_uri) ? content_blob_uri : 'missing').any?
      end

      def registered_as
        OpenbisExternalAsset.find_by_entity(self).seek_entity
      rescue ActiveRecord::RecordNotFound
        nil

        # the original Stuart's code (maybe needed to upgrade)
        # blob = ContentBlob.where(url: defined?(content_blob_uri) ? content_blob_uri : 'missing')
        # blob.any? ? blob.first.asset : nil
      end

      protected

      def json_key
        type_name.downcase.pluralize
      end

      private

      def query_application_server_by_perm_id(perm_id = '', cache_option = nil)
        cached_query_by_perm_id(perm_id, cache_option) do
          application_server_query_instance.query(entityType: type_name, queryType: 'ATTRIBUTE',
                                                  attribute: 'PermID', attributeValue: perm_id)
        end
      end

      def query_application_server_for_all(cache_option = nil)
        cached_query_by_perm_id('ALL:' + type_name, cache_option) do
          application_server_query_instance.query(entityType: type_name, queryType: 'ALL')
        end
      end

      def query_application_server_by_type_codes(codes, cache_option = nil)
        codes_str = codes.join(',')

        cached_query_by_type_codes(codes_str, cache_option) do
          application_server_query_instance.query(entityType: type_name, queryType: 'TYPE',
                                                  typeCodes: codes_str)
        end
      end

      def query_datastore_server_by_dataset_perm_id(perm_id = '', cache_option = nil)
        cached_query_by_perm_id(perm_id, cache_option) do
          datastore_server_query_instance.query(entityType: type_name, queryType: 'ATTRIBUTE',
                                                attribute: 'DataSetPermID', attributeValue: perm_id)
        end
      end

      def cached_query_by_perm_id(perm_id, cache_option = nil)
        raise 'Block required for doing query' unless block_given?
        key = cache_key(perm_id)
        Rails.logger.info("OBIS CACHE KEY = #{key}") if DEBUG
        openbis_endpoint.metadata_store.fetch(key, cache_option) do
          Rails.logger.info("OBIS NO CACHE, FETCHING FROM SERVER #{perm_id}") if DEBUG
          yield
        end
      end

      def cached_query_by_type_codes(codes_str, cache_option = nil)
        raise 'Block required for doing query' unless block_given?
        key = cache_key("TYPE_CODES:#{codes_str}")
        Rails.logger.info("OBIS CACHE KEY = #{key}") if DEBUG
        openbis_endpoint.metadata_store.fetch(key, cache_option) do
          Rails.logger.info("OBIS NO CACHE, FETCHING FROM SERVER #{codes_str}") if DEBUG
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
