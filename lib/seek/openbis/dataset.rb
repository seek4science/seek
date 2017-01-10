module Seek
  module Openbis
    class Dataset < Entity
      attr_reader :dataset_type, :experiment_id, :sample_ids, :properties

      def populate_from_json(json)
        @properties = json['properties']
        @properties.delete_if { |key, _value| key == '@type' }
        @dataset_type = json['dataset_type']
        @experiment_id = json['experiment']
        @sample_ids = json['samples'].last
        super(json)
      end

      def dataset_type_text
        txt = dataset_type_description
        txt = dataset_type_code if txt.blank?
        txt
      end

      def dataset_type_description
        dataset_type['description']
      end

      def dataset_type_code
        dataset_type['code']
      end

      def dataset_files
        @dataset_files ||= Seek::Openbis::DatasetFile.find_by_dataset_perm_id(perm_id)
      end

      def type_name
        'DataSet'
      end
    end
  end
end
