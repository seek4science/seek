module Seek
  module Git
    class Converter
      attr_reader :asset

      def initialize(asset)
        @asset = asset
      end

      def convert(unzip: false)
        repo = asset.create_local_git_repository
        asset.versions.map do |version|
          Dir.mktmpdir do |tmp_dir|
            git_version = asset.git_versions.build(git_repository: repo,
                                                   version: version.version,
                                                   name: "Version #{version.version}",
                                                   comment: version.revision_comments,
                                                   created_at: version.created_at)
            git_version.resource_attributes = version.attributes.slice(asset.class.versioned_columns)
            path_io_pairs = []
            version.all_content_blobs.map do |blob|
              if unzip && blob.original_filename.end_with?('.zip')
                Dir.chdir(tmp_dir) do
                  Zip::File.open(blob.filepath) do |zipfile|
                    zipfile.each_with_index do |entry, index|
                      local_path = "v#{version.version}_b#{blob.id}_#{index}"
                      zipfile.extract(entry, local_path)
                      path_io_pairs << [entry.name, File.open(local_path)]
                    end
                  end
                end
              else
                path_io_pairs << [blob.original_filename, blob.data_io_object]
              end
            end
            args = [path_io_pairs]
            args << version.revision_comments if version.revision_comments.present?
            git_version.add_files(*args)
            git_version.save
            git_version

            # TODO: Add annotations?
          end
        end

        repo
      end
    end
  end
end
