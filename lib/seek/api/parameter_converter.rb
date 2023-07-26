module Seek
  module Api
    ##
    # A class to convert JSON-API-structured parameters into a form that SEEK's controllers understand.
    # Four stages of conversion:
    # 1. De-serialize - The JSON-API parameters are converted into a Rails-esque form: params['data_file'] = { ... }
    # 2. Convert - Certain parameter values are converted according to the block passed to each `convert` declaration.
    # 3. Rename - Keys are renamed if a `convert` declaration has a `rename` key.
    # 4. Elevate - Parameters are moved up out of e.g. `params['data_file']` into the top-level `params`
    #              if the `elevate` option is set to `true`.
    class ParameterConverter
      # The JSON-API deserializer needs to know which fields are polymorphic, or the type info gets thrown away.
      POLYMORPHIC_FIELDS = {
        collection_items: [:asset]
      }

      def self.conversions
        @conversions ||= {}
      end

      class Conversion
        attr_reader :convert, :rename, :elevate

        def initialize(rename: nil, elevate: false, only: [], except: [], &block)
          @convert = block
          @rename = rename
          @elevate = elevate
          @only = Array(only)
          @except = Array(except)
        end

        def apply?(controller_name)
          if @only.length > 0
            @only.include?(controller_name)
          elsif @except.length > 0
            !@except.include?(controller_name)
          else
            true
          end
        end
      end

      def self.convert(*attrs, rename: nil, elevate: false, only: [], except: [], &block)
        attrs.each do |attr|
          attr = attr.to_sym
          conversions[attr] ||= []
          conversions[attr] << Conversion.new(rename: rename, elevate: elevate, only: only, except: except, &block)
        end
      end

      convert :policy, :default_policy, rename: :policy_attributes, elevate: true do |value|
        value[:access_type] = PolicyHelper::key_access_type(value.delete(:access))
        perms = {}
        (value.delete(:permissions) || []).each_with_index do |permission, index|
          contributor_id = permission[:resource][:id]
          contributor_type = permission[:resource][:type].singularize.classify

          perms[index.to_s] = {
            access_type: PolicyHelper::key_access_type(permission[:access]),
            contributor_type: contributor_type,
            contributor_id: contributor_id,
          }
        end
        value[:permissions_attributes] = perms

        value
      end

      convert :content_blobs, elevate: true do |value|
        (value || []).map do |cb|
          cb[:data_url] = cb.delete(:url)
          cb
        end
      end

      convert :publication_ids do |value|
        value.map { |id| "#{id}" }
      end

      convert :assay_class, rename: :assay_class_id do |value|
        if value && value[:key]
          AssayClass.where(key: value[:key]).pluck(:id).first
        end
      end

      convert :assay_type, rename: :assay_type_uri do |value|
        value[:uri]
      end

      convert :technology_type, rename: :technology_type_uri do |value|
        value[:uri]
      end

      convert :tags, rename: :tag_list, elevate: true do |value|
        if value
          value.join(', ')
        else
          ''
        end
      end

      convert :operation_annotations do |value|
        value.collect{|v| v[:identifier]}
      end

      convert :topic_annotations do |value|
        value.collect{|v| v[:identifier]}
      end

      convert :data_type_annotations do |value|
        value.collect{|v| v[:identifier]}
      end

      convert :data_format_annotations do |value|
        value.collect{|v| v[:identifier]}
      end

      convert :programme_ids, rename: :programme_id do |value|
        value.try(:first)
      end

      convert :model_type, rename: :model_type_id do |value|
        ModelType.find_by_title(value).try(:id)
      end

      convert :model_format, rename: :model_format_id do |value|
        ModelFormat.find_by_title(value).try(:id)
      end

      convert :environment, rename: :recommended_environment_id do |value|
        RecommendedModelEnvironment.find_by_title(value).try(:id)
      end

      convert :data_file_ids, rename: :data_files_attributes, except: [:events, :workflows] do |value|
        value.map { |i| { asset_id: i }.with_indifferent_access }
      end

      convert :sample_ids, rename: :samples_attributes do |value|
        value.map { |i| { asset_id: i }.with_indifferent_access }
      end

      convert :assay_ids, rename: :assay_assets_attributes do |value|
        value.map { |i| { assay_id: i } }
      end

      convert :workflow_class, rename: :workflow_class_id do |value|
        if value && value[:key]
          WorkflowClass.where(key: value[:key]).pluck(:id).first
        end
      end

      convert :asset_type do |value|
        value.classify
      end

      convert :creators, rename: :api_assets_creators do |value|
        value.map.with_index do |attrs, i|
          attrs[:pos] ||= (i + 1)
          profile = attrs.delete(:profile)
          attrs[:creator_id] = profile.split('/')&.last&.to_i if profile
          attrs
        end
      end

      convert :tools, rename: :tools_attributes, only: :workflows do |value|
        biotools_client = BioTools::Client.new
        value.map do |t|
          biotools_id = BioTools::Client.match_id(t[:id])
          next unless biotools_id
          name = t[:name]
          if name.blank?
            begin
              name = biotools_client.tool(biotools_id)['name']
            rescue StandardError => e
              Rails.logger.error("Error fetching bio.tools info for #{biotools_id}")
            end
          end

          { bio_tools_id: biotools_id, name: name }
        end.compact
      end

      convert :administrator_ids, rename: :programme_administrator_ids
      convert :attribute_map, rename: :data
      convert :content_blobs, elevate: true
      convert :discussion_links, rename: :discussion_links_attributes
      convert :expertise_list, elevate: true
      convert :revision_comments, elevate: true
      convert :template, rename: :template_attributes
      convert :tool_list, elevate: true

      def initialize(controller_name, options = {})
        @controller_name = controller_name
        @options = options
      end

      def convert(parameters)
        @parameters = parameters

        # Step 1 - JSON-API -> Rails format
        polymorphic_fields = POLYMORPHIC_FIELDS[@controller_name.to_sym] || []
        attributes = ActiveModelSerializers::Deserialization.jsonapi_parse(@parameters,
                                                                           polymorphic: polymorphic_fields,
                                                                           key_transform: :unaltered)

        new_attributes = {}
        elevated = {}
        attributes.each do |key, value|
          conversions = self.class.conversions[key.to_sym] || []
          if conversions.empty?
            new_attributes[key] = value
            next
          end
          conversions.each do |conversion|
            new_key = key
            new_value = value
            if conversion.apply?(@controller_name.to_sym)
              # Step 2 - Perform any conversions on parameter values
              new_value = conversion.convert.call(value, @parameters) if conversion.convert

              # Step 3 - Rename any parameter keys
              new_key = conversion.rename if conversion.rename

              # Step 4 - Move any parameters into top-level
              if conversion.elevate
                elevated[new_key] = new_value
                next
              end
            end

            new_attributes[new_key] = new_value
          end
        end

        @parameters[@controller_name.singularize.to_sym] = new_attributes
        @parameters.delete(:data)
        @parameters.merge!(elevated)

        @parameters
      end
    end
  end
end
