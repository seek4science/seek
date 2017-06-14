module Seek
  module Openbis
    # Represents an openBIS Experiment entity
    class Experiment < Entity
      attr_reader :experiment_type, :experiment_id, :sample_ids, :identifier, :dataset_ids, :properties

      def populate_from_json(json)
        @properties = json['properties']
        @properties.delete_if { |key, _value| key == '@type' }
        @experiment_type = json['experiment_type']
        @dataset_ids = json['datasets'].last
        @sample_ids = json['samples'].last
        @identifier = json['identifier']
        super(json)
      end

      def experiment_type_description
        experiment_type['description']
      end

      def experiment_type_code
        experiment_type['code']
      end

      def experiment_type_text
        txt = experiment_type_description
        txt = experiment_type_code if txt.blank?
        txt
      end

      def type_name
        'Experiment'
      end
    end
  end
end
