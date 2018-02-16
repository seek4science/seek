module Seek
  module Templates
    # populates an Assay with the metadata that can be found in a Rightfield Template
    class AssayRightfieldExtractor < RightfieldExtractor
      def populate(assay)
        unless title.blank?
          assay.title = title
          assay.description = description
          assay.assay_type_uri = assay_type_uri
          assay.technology_type_uri = technology_type_uri
          assay.study = study if study
        end
      end

      def study
        id = seek_id_by_type(Study)
        Study.find_by_id(id) if id
      end

      def title
        value_for_property_and_index(:title, 1)
      end

      def description
        value_for_property_and_index(:description, 1)
      end

      def assay_type_uri
        value_for_property_and_index(:hasType, 0)
      end

      def technology_type_uri
        value_for_property_and_index(:hasType, 1)
      end
    end
  end
end
