# A class for converting a ContentBlob-backed asset to use a Git repository.
module Git
  class Converter
    attr_reader :asset

    def initialize(asset)
      @asset = asset
    end

    def convert(unzip: false, overwrite: false)
      if overwrite
        disable_authorization_checks { asset.local_git_repository&.destroy! }
        repo = asset.create_local_git_repository
      else
        repo = asset.local_git_repository || asset.create_local_git_repository
      end
      asset.standard_versions.order(:version).each do |version|
        convert_version(repo, version, unzip: unzip)
      end

      repo
    end

    def convert_version(repo, version, unzip: false)
      Dir.mktmpdir do |tmp_dir|
        git_version = asset.git_versions.where(git_repository: repo, version: version.version).first_or_initialize
        git_version.assign_attributes(name: "Version #{version.version}",
                                      comment: version.revision_comments,
                                      doi: version.doi,
                                      contributor_id: version.contributor_id,
                                      visibility: version.visibility,
                                      created_at: version.created_at,
                                      updated_at: version.updated_at)
        attribute_keys = asset.class.versioned_columns.map(&:name)
        attribute_keys.delete('revision_comments')
        attribute_keys.delete('contributor_id')
        git_version.set_resource_attributes(version.attributes.slice(*attribute_keys))
        path_io_url_triples = []
        version.all_content_blobs.map do |blob|
          if unzip && blob.original_filename.end_with?('.zip')
            blob_dir = File.join(tmp_dir, "blob_#{blob.id}")
            Dir.mkdir(blob_dir)
            Dir.chdir(blob_dir) do
              ROCrate::Reader.unzip_file_to(blob.filepath, blob_dir)
              files = Dir.glob('**/*', ::File::FNM_DOTMATCH).select do |path|
                ::File.file?(path) && !(path == '.' || path == '..' || path.end_with?('/.'))
              end
              # Don't include generated RO-Crate files for basic crates
              if blob.original_filename.end_with?('.basic.crate.zip')
                files.delete('ro-crate-metadata.json')
                files.delete('ro-crate-metadata.jsonld')
                files.delete('ro-crate-preview.html')
              end
              path_io_url_triples += files.map { |f| [f, File.open(f)] }
            end
          else
            tuple = [blob.original_filename, blob.data_io_object || StringIO.new('')]
            tuple << blob.url if blob.url
            path_io_url_triples << tuple
          end

          annotate_version(blob, git_version)
        end

        User.with_current_user(version.contributor.user) do
          git_version.with_git_author(name: version.contributor.name,
                                      email: version.contributor.email,
                                      time: version.created_at.to_time) do
            git_version.add_files(path_io_url_triples, message: version.revision_comments.present? ? version.revision_comments : nil)

            # Create annotations indicating which files came from URLs
            path_io_url_triples.each do |path, _, url|
              git_version.git_annotations.build(path: path, key: 'remote_source', value: url) if url
            end
          end
          git_version.mutable = version.version == version.versions.maximum(:version)
          git_version.save!
        end
        git_version
      end
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
