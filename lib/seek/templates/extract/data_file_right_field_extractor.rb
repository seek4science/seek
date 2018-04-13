module Seek
  module Templates
    module Extract
      # populates a data file with the metadata that can be found in Rightfield template
      class DataFileRightFieldExtractor < RightfieldExtractor
        def populate(data_file)
          data_file.title = title
          data_file.description = description
          data_file.projects = [project] if project
          assay.associate(data_file) if assay
        end

        def assay
          id = seek_id_by_type(Assay)
          Assay.find_by_id(id) if id
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
