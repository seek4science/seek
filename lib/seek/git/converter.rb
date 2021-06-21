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
                  ROCrate::Reader.unzip_file_to(blob.filepath, blob_dir)
                  files = Dir.glob('**/*').select { |e| File.file? e }
                  # Don't include generated RO-Crate files for basic crates
                  if blob.original_filename.end_with?('.basic.crate.zip')
                    files.delete('ro-crate-metadata.json')
                    files.delete('ro-crate-metadata.jsonld')
                    files.delete('ro-crate-preview.html')
                  end
                  path_io_pairs += files.map { |f| [f, File.open(f)] }
                end
              else
                path_io_pairs << [blob.original_filename, blob.data_io_object]
              end
              annotate_version(blob, git_version)
            end
            User.with_current_user(version.contributor.user) do
              git_version.with_git_author(name: version.contributor.name,
                                          email: version.contributor.email,
                                          time: version.created_at.to_time) do
                git_version.add_files(path_io_pairs, message: version.revision_comments.present? ? version.revision_comments : nil)
              end
              git_version.save!
            end
            git_version
          end
        end

        repo
      end

      private

      def annotate_version(blob, git_version)
        if asset.is_a?(Workflow)
          if blob.original_filename.end_with?('crate.zip')
            crate = ROCrate::WorkflowCrateReader.read(blob)
            main_workflow_path = crate.main_workflow&.id
            diagram_path = crate.main_workflow&.diagram&.id
            abstract_cwl_path = crate.main_workflow&.cwl_description&.id

            git_version.main_workflow_path ||= URI.decode_www_form_component(main_workflow_path) unless main_workflow_path.blank?
            git_version.diagram_path ||= URI.decode_www_form_component(diagram_path) unless diagram_path.blank?
            git_version.abstract_cwl_path ||= URI.decode_www_form_component(abstract_cwl_path) unless abstract_cwl_path.blank?
          # If it's a workflow with just a single file that isn't an RO-Crate, use that as the main workflow
          elsif asset.all_content_blobs.count == 1
            git_version.main_workflow_path ||= blob.original_filename
          end
        end
      end
    end
  end
end
