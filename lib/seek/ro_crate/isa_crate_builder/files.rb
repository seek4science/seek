module Seek
  module RoCrate
    class ISACrateBuilder
      # File entities for the data files of an assay, placed in the assay's dataset directory.
      module Files
        private

        # The data files the user can view, as File entities at "<assay dir>dataset/<original filename>".
        # The entity carries metadata only; whether the bytes are packed into the zip is decided when
        # the crate is written.
        def file_entities(crate, assay_dir, assay)
          viewable(assay.data_files).map { |data_file| file_entity(crate, assay_dir, data_file) }
        end

        def file_entity(crate, assay_dir, data_file)
          blob = data_file.content_blob
          path = "#{assay_dir}dataset/#{blob&.original_filename.presence || data_file.title}"
          entity = ::ROCrate::DataEntity.new(crate, nil, path, '@type' => 'File')
          set(entity, file_properties(data_file, blob))
          crate.add_data_entity(entity)
        end

        def file_properties(data_file, blob)
          { 'name' => data_file.title,
            'description' => data_file.description,
            'identifier' => data_file.rdf_seek_id,
            'encodingFormat' => blob&.content_type,
            'contentSize' => blob&.file_size,
            'sha1' => blob&.sha1sum.presence,
            'contentUrl' => content_url(data_file, blob) }
        end

        # The remote link for a blob that only points at a URL and holds no local copy, otherwise the
        # SEEK download URL.
        def content_url(data_file, blob)
          return if blob.nil?
          return blob.url if blob.url.present? && !blob.file_exists?

          Seek::Util.routes.polymorphic_url([data_file, blob], action: :download)
        end
      end
    end
  end
end
