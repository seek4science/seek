module Seek
  module Api
    ##
    # A class to convert JSON-API-structured parameters into a form that SEEK's controllers understand.
    # Four stages of conversion:
    # 1. De-serialize - The JSON-API parameters are converted into a Rails-esque form: params['data_file'] = { ... }
    # 1. Convert - Certain parameter values are converted according to the `CONVERSIONS` mapping between keys and procs.
    # 3. Rename - Keys the above form are renamed according to the `RENAME` mapping below.
    # 4. Elevate - Parameters in the `ELEVATE` list are moved up out of e.g. `params['data_file']` into the top-level `params`
    class ParameterConverter
      # Custom conversions required on certain parameters to fit how the controller expects.
      CONVERSIONS = {
          policy: ->(value) {
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
          },

          content_blobs: ->(value) {
            (value || []).map do |cb|
              cb[:data_url] = cb.delete(:url)
              cb
            end
          },

          publication_ids: ->(value) {
            value.map { |id| "#{id}," }
          },

          assay_class: ->(value) {
            if value && value[:key]
              AssayClass.where(key: value[:key]).pluck(:id).first
            end
          },

          assay_type: ->(value) {
            value[:uri]
          },

          technology_type: ->(value) {
            value[:uri]
          },

          tags: ->(value) {
            if value
              value.join(', ')
            else
              ''
            end
          },

          funding_codes: ->(value) {
            if value
              value.join(', ')
            else
              ''
            end
          },

          programme_ids: ->(value) {
            value.try(:first)
          },

          model_type: ->(value) {
            ModelType.find_by_title(value).try(:id)
          },

          model_format: ->(value) {
            ModelFormat.find_by_title(value).try(:id)
          },

          environment: ->(value) {
            RecommendedModelEnvironment.find_by_title(value).try(:id)
          },

          data_file_ids: ->(value) {
            value.map { |i| { 'asset_id' => i }.with_indifferent_access }
          },

          assay_ids: ->(value) {
            value.map { |i| { assay_id: i } }
          }
      }
      CONVERSIONS[:default_policy] = CONVERSIONS[:policy]
      CONVERSIONS.freeze

          # Parameters to rename
      RENAME = {
          tags: :tag_list,
          policy: :policy_attributes,
          default_policy: :policy_attributes,
          assay_class: :assay_class_id,
          assay_type: :assay_type_uri,
          technology_type: :technology_type_uri,
          programme_ids: :programme_id,
          model_type: :model_type_id,
          model_format: :model_format_id,
          environment: :recommended_environment_id,
          data_file_ids: :data_files_attributes,
          assay_ids: :assay_assets_attributes,
          discussion_links: :discussion_links_attributes
      }.freeze

      # Parameters to "elevate" out of params[bla] to the top-level.
      ELEVATE = %i[tag_list expertise_list tool_list policy_attributes content_blobs revision_comments].freeze

      def initialize(controller_name, options = {})
        @controller_name = controller_name
        @options = options
      end

      def convert(parameters)
        @parameters = parameters

        # Step 1 - JSON-API -> Rails format
        @parameters[@controller_name.singularize.to_sym] =
            ActiveModelSerializers::Deserialization.jsonapi_parse(@parameters)

        # Step 2 - Perform any conversions on parameter values
        convert_parameters

        # Step 3 - Rename any parameter keys
        rename_parameters

        # Step 4 - Move any parameters into top-level
        elevate_parameters

        @parameters.delete(:data)
        @parameters
      end

      private

      def convert_parameters
        attributes.each do |key, value|
          unless (conversion = CONVERSIONS[key.to_sym]).nil? || exclude?(:convert, key)
            attributes[key] = conversion.call(value)
          end
        end
      end

      def rename_parameters
        RENAME.each do |key, new_key|
          if attributes.key?(key) && !exclude?(:rename, key)
            attributes[new_key] = attributes.delete(key)
          end
        end
      end

      def elevate_parameters
        ELEVATE.each do |key|
          if attributes.key?(key) && !exclude?(:elevate, key)
            @parameters[key] = attributes.delete(key)
          end
        end
      end

      def attributes
        @parameters[@controller_name.singularize.to_sym] || {}
      end

      def exclude?(type, key)
        (@options[:skip] || []).include?(key.to_sym) ||
        (@options["skip_#{type}".to_sym] || []).include?(key.to_sym)
      end
    end
  end
end
