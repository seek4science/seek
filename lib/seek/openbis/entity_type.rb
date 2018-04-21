module Seek
  module Openbis
    # General behaviour for an entity type in openBIS.
    class EntityType
      attr_reader :json, :modification_date, :code, :description,
                  :perm_id, :openbis_endpoint, :entity_type, :exception

      # debug is with puts so it can be easily seen on tests screens
      DEBUG = Seek::Config.openbis_debug ? true : false

      @@TYPES = ['Sample', 'DataSet', 'Experiment']

      def self.SampleType(openbis_endpoint, code = nil, refresh = false)
        EntityType.new(openbis_endpoint, 'Sample', code, refresh)
      end

      def self.DataSetType(openbis_endpoint, code = nil, refresh = false)
        EntityType.new(openbis_endpoint, 'DataSet', code, refresh)
      end

      def self.ExperimentType(openbis_endpoint, code = nil, refresh = false)
        EntityType.new(openbis_endpoint, 'Experiment', code, refresh)
      end

      def ==(other)
        perm_id == other.perm_id
      end

      def initialize(openbis_endpoint, entity_type, code = nil, refresh = false)
        @openbis_endpoint = openbis_endpoint
        @entity_type = entity_type

        unless @openbis_endpoint && @openbis_endpoint.is_a?(OpenbisEndpoint)
          raise 'OpenbisEndpoint expected and required'
        end

        unless @@TYPES.include? @entity_type
          raise "Unsupported type: #{@entity_type}"
        end

        if code

          cache_option = refresh ? { force: true } : nil
          begin
            json = query_application_server_by_code(code, cache_option)
            unless json[json_key]
              raise Seek::Openbis::EntityNotFoundException, "Unable to find #{type_name} with code #{code}"
            end
            populate_from_json(json[json_key].first)
          rescue Fairdom::OpenbisApi::OpenbisQueryException => e
            @exception = e
          end
        end
      end

      def type_name
        @entity_type+'Type'
      end

      def populate_from_json(json)
        # for debug by TZ
        puts "Populates #{self.class} #{@entity_type} from json:" if DEBUG
        puts json if DEBUG
        puts '-----' if DEBUG
        @json = json
        @code = json['code']
        @description = json['description']
        @perm_id = json['permId']
        @modification_date = DateTime.parse(json['modificationDate'])
        self
      end

      def all(refresh = false)
        cache_option = refresh ? { force: true } : nil
        json = query_application_server_for_all(cache_option)
        construct_from_json(json, entity_type)
      end

      def find_by_semantic(semantic, refresh = false)
        cache_option = refresh ? { force: true } : nil

        json = query_application_server_by_semantic(semantic, cache_option)
        construct_from_json(json, entity_type)
      end

      def find_by_codes(codes, refresh = false)
        cache_option = refresh ? { force: true } : nil

        json = query_application_server_by_code(codes.join(","), cache_option)
        construct_from_json(json, entity_type)
      end

      def construct_from_json(json, entity_type)
        return [] unless json[json_key]
        json[json_key].collect do |element|
          self.class.new(openbis_endpoint, entity_type).populate_from_json(element)
        end.sort_by(&:code)
      end


      def cache_key(code)
        "#{type_name}/#{Digest::SHA2.hexdigest(code)}"
      end

      def error_occurred?
        !exception.nil?
      end

      protected

      def json_key
        type_name.downcase.pluralize
      end

      private

      def query_application_server_for_all(cache_option = nil)
        cached_query_by_code('ALL:'+type_name, cache_option) do
          application_server_query_instance.query(entityType: type_name, queryType: 'ALL')
        end
      end

      def query_application_server_by_code(code, cache_option = nil)
        cached_query_by_code(code, cache_option) do
          application_server_query_instance.query(entityType: type_name, queryType: 'ATTRIBUTE',
                                                  attribute: 'CODE', attributeValue: code)
        end
      end

      def query_application_server_by_semantic(semantic, cache_option = nil)
        cache_code = type_name+':'+semantic.to_json
        query = { entityType: type_name, queryType: 'SEMANTIC' }
        query[:predicateOntologyId] = semantic.predicateOntologyId if semantic.predicateOntologyId
        query[:predicateOntologyVersion] = semantic.predicateOntologyVersion if semantic.predicateOntologyVersion
        query[:predicateAccessionId] = semantic.predicateAccessionId if semantic.predicateAccessionId
        query[:descriptorOntologyId] = semantic.descriptorOntologyId if semantic.descriptorOntologyId
        query[:descriptorOntologyVersion] = semantic.descriptorOntologyVersion if semantic.descriptorOntologyVersion
        query[:descriptorAccessionId] = semantic.descriptorAccessionId if semantic.descriptorAccessionId

        cached_query_by_code(cache_code, cache_option) do
          application_server_query_instance.query(query)
        end
      end

      def cached_query_by_code(code, cache_option = nil)
        raise 'Block required for doing query' unless block_given?
        key = cache_key(code)
        Rails.logger.info("OBIS CACHE KEY = #{key}") if DEBUG
        openbis_endpoint.metadata_store.fetch(key, cache_option) do
          Rails.logger.info("OBIS NO CACHE, FETCHING FROM SERVER #{code}") if DEBUG
          yield
        end
      end

      def application_server_query_instance
        Fairdom::OpenbisApi::ApplicationServerQuery.new(openbis_endpoint.as_endpoint, openbis_endpoint.session_token)
      end

    end
  end
end
