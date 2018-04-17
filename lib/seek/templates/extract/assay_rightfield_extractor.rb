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
            assay.sops << sop if sop
            if study
              assay.study = study
              check_for_duplicate_assay(assay)
            else
              add_warning(Warnings::NO_STUDY, nil)
            end

          end
          @warnings
        end

        private

        def study
          item_for_type(Study, 'edit')
        end

        def sop
          item_for_type(Sop, 'view')
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

        def check_for_duplicate_assay(assay)
          if !assay.title.blank? && assay.study
            dup_assay = assay.study.assays.where(title: assay.title).first
            add_warning(Warnings::DUPLICATE_ASSAY, nil, dup_assay) if dup_assay
          end
        end
      end
    end
  end
end
