module Seek
  module Openbis
    class Dataset < Entity

      attr_reader :dataset_type,:experiment_id,:sample_ids

      def populate_from_json(json)
        @dataset_type=json["dataset_type"]
        @experiment_id = json["experiment"]
        @sample_ids = json["samples"].last
        super(json)
      end

      def dataset_type_text
        txt = dataset_type_description
        txt = dataset_type_code if txt.blank?
        txt
      end

      def dataset_type_description
        dataset_type["description"]
      end

      def dataset_type_code
        dataset_type["code"]
      end

      def dataset_file
        Seek::Openbis::DatasetFile.new(perm_id)
      end

      def type_name
        'DataSet'
      end
    end
  end
end