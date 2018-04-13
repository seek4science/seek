module Seek
  module Templates
    module Extract
      # populates an Assay with the metadata that can be found in a Rightfield Template
      class AssayRightfieldExtractor < RightfieldExtractor
        def populate(assay)
          unless title.blank?
            assay.title = title
            assay.description = description
            assay.assay_type_uri = assay_type_uri
            assay.technology_type_uri = technology_type_uri
            assay.study = study if study
            assay.sops << sop if sop
          end
        end

        def study
          id = seek_id_by_type(Study)
          Study.find_by_id(id) if id
        end

        def sop
          id = seek_id_by_type(Sop)
          Sop.find_by_id(id) if id
        end

        def title
          value_for_property_and_index(:title, :literal, 1)
        end

        def description
          value_for_property_and_index(:description, :literal, 1)
        end

        def assay_type_uri
          value_for_property_and_index(:hasType, :term_uri, 0)
        end

        def technology_type_uri
          value_for_property_and_index(:hasType, :term_uri, 1)
        end
      end
    end
  end
end
