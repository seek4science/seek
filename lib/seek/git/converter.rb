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
            annotate_version(git_version)
            git_version.save!
            git_version
          end
        end

        repo
      end

      private

      def annotate_version(git_version)
        if git_version.ro_crate? && asset.is_a?(Workflow)
          git_version.in_temp_dir do |dir|
            crate = ROCrate::WorkflowCrateReader.read(dir)
            main_workflow_path = crate.main_workflow&.id
            diagram_path = crate.main_workflow&.diagram&.id
            abstract_cwl_path = crate.main_workflow&.cwl_description&.id

            annotations_attributes = {}
            annotations_attributes['1'] = { key: 'main_workflow', path: main_workflow_path } unless main_workflow_path.blank?
            annotations_attributes['2'] = { key: 'diagram', path: diagram_path } unless diagram_path.blank?
            annotations_attributes['3'] = { key: 'abstract_cwl', path: abstract_cwl_path } unless abstract_cwl_path.blank?
            git_version.git_annotations_attributes = annotations_attributes
          end
        end
      end
    end
  end
end
