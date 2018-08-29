module Seek
  module Templates
    module Extract
      # populates a data file with the metadata that can be found in Rightfield template
      class DataFileRightFieldExtractor < RightfieldExtractor
        def populate(data_file)
          if contains_rightfield_elements?
            data_file.title = title
            data_file.description = description
            data_file.projects = [project] if project
            data_file.assay_assets.build(assay: assay) if assay
          end
          warnings
        end

        def assay
          item_for_type(Assay, 'edit')
        end

        def title
          value_for_property_and_index(:title, :literal, 0)
        end

        def description
          value_for_property_and_index(:description, :literal, 0)
        end
      end
    end
  end
end
