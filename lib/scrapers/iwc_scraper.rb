module Scrapers
  class IwcScraper < GithubScraper

    private

    def read_crate(git)
      dir = git.dir.path
      Dir.chdir(dir) do
        crate = ROCrate::WorkflowCrate.new
        # Get some metadata from the first workflow listed in .dockstore.yml
        dockstore_meta = YAML.load(File.read('.dockstore.yml'))
        workflow_meta = dockstore_meta['workflows'][0]
        # Add everything from the Git repository to the RO-Crate, except main workflow which is added later.
        main_wf_path = workflow_meta['primaryDescriptorPath'].sub(/\A\.?\//, '')
        Dir.glob('**/*', File::FNM_DOTMATCH).each do |path| # Include things beginning with . except .git, . and ..
        next if ['.git', '.', '..', main_wf_path].include?(path)
        next if path.end_with?('/.')
        next if path.start_with?('.git/')
        if File.directory?(path)
          crate.add_directory(path, path)
        else
          f = crate.add_file(path, path)
          f.content_size = File.size(path)
        end
        end

        # Add main workflow and metadata from workflow extractor & .dockstore.yml
        main_wf = crate.add_file(File.open(main_wf_path), entity_class: ROCrate::Workflow, name: workflow_meta['name'])
        lang_meta = Object.const_get("Seek::WorkflowExtractors::#{workflow_meta['subclass']}").workflow_class.ro_crate_metadata
        main_wf.programming_language = ROCrate::ContextualEntity.new(crate, nil, lang_meta)
        main_wf.content_size = File.size(main_wf_path)

        # Set crate metadata
        crate.main_workflow = main_wf
        crate.name = "#{workflow_meta['name']} (#{git.describe(nil, tags: true, abbrev: 0)})"

        crate
      end
    end

    # Filter repositories to only register repos with .dockstore.yml present.
    def list_repositories
      super.select do |repo|
        sleep 1
        begin
          github["repos/#{repo['full_name']}/contents/.dockstore.yml"].head
          sleep 1
        rescue RestClient::NotFound
          puts "No .dockstore.yml found in #{repo['full_name']}, skipping"
        end
      end
    end
  end
end