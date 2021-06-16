# A class for converting a ContentBlob-backed asset to use a Git repository.
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
                blob_dir = File.join(tmp_dir, "blob_#{blob.id}")
                Dir.mkdir(blob_dir)
                Dir.chdir(blob_dir) do
                  Zip::File.open(blob.filepath) do |zipfile|
                    zipfile.each_with_index do |entry, index|
                      zipfile.extract(entry, entry.name)
                      path_io_pairs << [entry.name, File.open(entry.name)]
                    end
                  end

                  annotate_version(git_version) if blob.original_filename.end_with?('crate.zip')
                end
              else
                path_io_pairs << [blob.original_filename, blob.data_io_object]
              end
            end
            args = [path_io_pairs]
            args << version.revision_comments if version.revision_comments.present?
            git_version.with_git_author(name: version.contributor.name,
                                        email: version.contributor.email,
                                        time: version.created_at.to_time) do
              git_version.add_files(*args)
            end
            git_version.save!
            git_version
          end
        end

        repo
      end

      private

      def annotate_version(git_version)
        if asset.is_a?(Workflow)
          crate = ROCrate::WorkflowCrateReader.read(Dir.pwd)
          main_workflow_path = crate.main_workflow&.id
          diagram_path = crate.main_workflow&.diagram&.id
          abstract_cwl_path = crate.main_workflow&.cwl_description&.id

          git_version.main_workflow_path = main_workflow_path unless main_workflow_path.blank?
          git_version.diagram_path = diagram_path unless diagram_path.blank?
          git_version.abstract_cwl_path = abstract_cwl_path unless abstract_cwl_path.blank?
        end
      end
    end
  end
end
