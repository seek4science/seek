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
              perms[index.to_s] = {
                  access_type: PolicyHelper::key_access_type(permission[:access]),
                  contributor_type: permission[:resource_type].singularize.classify,
                  contributor_id: permission[:resource_id],
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

          creator_ids: ->(value) {
            value.map { |id| ['', id.to_i] }.to_json
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
            value.join(', ')
          },

          funding_codes: ->(value) {
            value.join(', ')
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
            value.map { |i| { 'id' => i }.with_indifferent_access }
          }
      }.freeze

      # Parameters to rename
      RENAME = {
          tags: :tag_list,
          policy: :policy_attributes,
          creator_ids: :creators,
          publication_ids: :related_publication_ids,
          assay_class: :assay_class_id,
          assay_type: :assay_type_uri,
          technology_type: :technology_type_uri,
          programme_ids: :programme_id,
          model_type: :model_type_id,
          model_format: :model_format_id,
          environment: :recommended_environment_id,
          data_file_ids: :data_files,
      }.freeze

      # Parameters to "elevate" out of params[bla] to the top-level.
      ELEVATE = %i[assay_organism_ids tag_list expertise_list tool_list policy_attributes content_blobs
       assay_ids related_publication_ids revision_comments creators data_files].freeze

      def initialize(controller_name)
        @controller_name = controller_name
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
          unless (conversion = CONVERSIONS[key.to_sym]).nil?
            attributes[key] = conversion.call(value)
          end
        end
      end

      def rename_parameters
        RENAME.each do |key, new_key|
          if attributes.key?(key)
            attributes[new_key] = attributes.delete(key)
          end
        end
      end

      def elevate_parameters
        ELEVATE.each do |key|
          if attributes.key?(key)
            @parameters[key] = attributes.delete(key)
          end
        end
      end

      def attributes
        @parameters[@controller_name.singularize.to_sym] || {}
      end
    end
  end
end