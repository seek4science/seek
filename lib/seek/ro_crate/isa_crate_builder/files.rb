module Seek
  module RoCrate
    class ISACrateBuilder
      # File entities for the data files of an assay, placed in the assay's dataset directory.
      module Files
        private

        # The data files the user can view, as File entities at "<assay dir>dataset/<original filename>".
        # A file the user may download, held locally and within the size limit, gets its content packed
        # into the zip; any other file is listed with its metadata and contentUrl only.
        def file_entities(crate, assay_dir, assay)
          viewable(assay.data_files).map { |data_file| file_entity(crate, assay_dir, data_file) }
        end

        def file_entity(crate, assay_dir, data_file)
          blob = data_file.content_blob
          path = "#{assay_dir}dataset/#{blob&.original_filename.presence || data_file.title}"
          entity = if packable?(data_file, blob)
                     ::ROCrate::File.new(crate, blob.filepath, path, '@type' => 'File')
                   else
                     ::ROCrate::DataEntity.new(crate, nil, path, '@type' => 'File')
                   end
          set(entity, file_properties(data_file, blob))
          crate.add_data_entity(entity)
        end

        def packable?(data_file, blob)
          blob.present? && blob.file_exists? && blob.file_size.to_i <= MAX_PACKED_FILE_SIZE &&
            data_file.can_download?(user)
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
