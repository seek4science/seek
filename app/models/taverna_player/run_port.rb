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
  class RunPort < ActiveRecord::Base
    include TavernaPlayer::Concerns::Models::RunPort

    def file_extension
      if metadata.nil?
        nil
      else
        if metadata[:type].is_a?(Array)
          type = metadata[:type].flatten.first # This works because list elements always share a mimetype
        else
          type = metadata[:type]
        end

        if Seek::MimeTypes::MIME_MAP[type]
          ext = Seek::MimeTypes::MIME_MAP[type][:extensions].first
          if ext.blank?
            nil
          else
            ".#{ext}"
          end
        else
          nil
        end
      end
    end

    # Overriding because we have modified the results zip file to give file extensions to each output value
    def deep_value(index)
      path = index.map { |i| i + 1 }.join("/")
      if value_is_error?(index)
        path += ".error"
      elsif !(ext = file_extension).nil?
        path += ext
      end

      read_file_from_zip(file.path, path)
    end

    def filename
      if depth == 0
        if !(ext = file_extension).nil?
          "#{name}#{ext}"
        else
          name
        end
      else
        "#{name}.zip"
      end
    end
  end

  class RunPort::Input < RunPort
    include TavernaPlayer::Concerns::Models::Input
    include TavernaPlayer::Concerns::Models::DataFileInput

  end

  class RunPort::Output < RunPort
    include TavernaPlayer::Concerns::Models::Output
  end
end