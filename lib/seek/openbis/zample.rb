module Seek
  module Openbis
    # Represents an openBIS Sample entity
    class Zample < Entity
      attr_reader :sample_type, :experiment_id, :dataset_ids, :identifier, :properties

      def populate_from_json(json)
        @properties = json['properties']
        @properties.delete_if { |key, _value| key == '@type' }
        @sample_type = json['sample_type']
        @dataset_ids = json['datasets']
        @experiment_id = json['experiment']
        @identifier = json['identifier']
        super(json)
      end

      # @deprecated
      def content_blob_uri
        "openbis:#{openbis_endpoint.id}:zample:#{perm_id}"
      end

      def sample_type_text
        txt = sample_type_description
        txt = sample_type_code if txt.blank?
        txt
      end

      def sample_type_description
        sample_type['description']
      end

      def sample_type_code
        sample_type['code']
      end

      def type_name
        'Sample'
      end

      def type_code
        sample_type_code
      end

      def type_description
        sample_type_description
      end

      def type_text
        sample_type_text
      end
    end
  end
end
