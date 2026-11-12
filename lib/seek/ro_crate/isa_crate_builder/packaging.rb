module Seek
  module RoCrate
    class ISACrateBuilder
      # Writes the crate as a zip: the metadata, the packed data files, and an entry for every
      # study, assay and dataset directory so readers find the directories the metadata names.
      module Packaging
        def write_zip(path)
          ::ROCrate::Writer.new(crate).write_zip(path, skip_preview: true)
          Zip::File.open(path) do |zip|
            directory_ids.each { |dir| zip.mkdir(dir.chomp('/')) unless zip.find_entry(dir) }
          end
          path
        end

        private

        # Every directory the metadata names: dataset directories plus the parents of every file.
        def directory_ids
          ids = crate.data_entities.map(&:id)
          dirs = ids.select { |id| id.end_with?('/') }
          ids.each do |id|
            parent = ::File.dirname(id)
            while parent != '.'
              dirs << "#{parent}/"
              parent = ::File.dirname(parent)
            end
          end
          dirs.uniq.sort
        end
      end
    end
  end
end
