module TavernaPlayer#
  module Concerns
    module Models
      module DataFileInput
        extend ActiveSupport::Concern

        included do
          attr_accessible :data_file_id
          before_save :assign_data_file_content
          belongs_to :data_file
        end

        def assign_data_file_content
          unless data_file_id.blank?
            df = DataFile.find(data_file_id)
            File.open(df.content_blob.filepath) do |f|
              self.file = f
              self.data_file_version=df.version
            end
          end
        end

        def suitable_data_files
          #possibility to filter by metadata here if the instantiated RunPort has the info
          DataFile.all_authorized_for :download
        end

      end
    end
  end
end