require 'rest-client'
require 'json'
require 'git'
require 'ro_crate'
require 'pathname'

module Scrapers
  class GithubScraper
    GIT_DESTINATION = Rails.root.join('tmp', 'scrapers', 'git')
    CRATE_DESTINATION = Rails.root.join('tmp', 'scrapers', 'crates')
    CACHE_DESTINATION = Rails.root.join('tmp', 'scrapers', 'cache')

    def initialize(organization, project, contributor, main_branch: 'master', debug: false)
      @organization = organization # The GitHub organization to scrape
      raise "Missing GitHub organization" unless @organization
      @project = project # The SEEK project who will own the resources
      raise "Missing project" unless @project
      @contributor = contributor # The SEEK person who will submit the resources
      raise "Missing contributor" unless @contributor
      @debug = debug # If debug is set, don't persist anything to database
      @main_branch = main_branch # The name of the main/master branch
      if @debug
        puts "Org: #{@organization}"
        puts "Project: #{@project.title} (ID: #{@project.id})"
        puts "Contributor: #{@contributor.title} (ID: #{@contributor.id}, user ID: #{@contributor.user.id})"
      end
    end

    def scrape
      User.with_current_user(@contributor.user) do
        puts "Listing #{@organization} repos"
        repo_list = list_repositories

        puts "Cloning #{@organization} repos"
        repositories = clone_repositories(repo_list)

        puts "Building RO-Crates"
        crates = repositories.map do |git|
          build_workflow_ro_crate(git)
        end

        puts "Building SEEK resources"
        resources = resources(crates)

        puts "Registering SEEK resources"
        resources = register(resources)
        successes, failures = resources.partition(&:persisted?)

        if successes.any?
          puts "Registered:"
          successes.each { |w| puts " * #{w} - #{w.title}" }
        end

        if failures.any?
          puts "Not registered:"
          failures.each do |w|
            puts " * #{w.title}"
            w.errors.full_messages.each { |e| puts "     #{e}" }
          end
        end

        resources
      end
    end

    private

    # Instantiate SEEK resources (E.g. workflows) for each of the given RO-Crates.
    def resources(crate_paths)
      crate_paths.map do |crate_path|
        workflow = Workflow.new

        workflow.build_content_blob(
            tmp_io_object: File.open(crate_path),
            original_filename: Pathname.new(crate_path).basename,
            content_type: 'application/zip',
            make_local_copy: true,
            file_size: File.size(crate_path)
        )
        workflow.assign_attributes(Seek::WorkflowExtractors::ROCrate.new(File.open(crate_path)).metadata.except(:errors, :warnings))
        workflow.contributor = @contributor
        workflow.projects = Array(@project)
        workflow.policy = Policy.projects_policy(workflow.projects)
        workflow.policy.access_type = Policy::ACCESSIBLE

        workflow
      end
    end

    # If the resource has already been registered, find it.
    def existing_resource(resource)
      @project.workflows.joins(:source_link).where(asset_links: { url: resource.source_link_url }).first
    end

    # Decide whether a new version of `existing_resource` should be created using the metadata from `resource`.
    def should_create_new_version?(resource, existing_resource)
      resource.ro_crate['softwareVersion'] != existing_resource.ro_crate['softwareVersion']
    end

    # Register (save) the given SEEK resources. If a resource was already registered, either skip it or create a new
    # version, depending on some given criteria.
    def register(resources)
      registered = []
      resources.each do |resource|
        puts " Considering: #{resource.title}"
        existing = existing_resource(resource)
        if existing
          version = resource.ro_crate['softwareVersion']
          existing_version = existing.ro_crate['softwareVersion']
          if should_create_new_version?(existing, resource)
            puts "  New version detected! (#{version} vs. #{existing_version}), creating new version"
            unless @debug
              old_content_blob = existing.content_blob
              new_content_blob = resource.content_blob
              new_content_blob.asset_version = (existing.version + 1)
              existing.assign_attributes(resource.extractor.metadata.except(:warnings, :errors))
              existing.content_blob = new_content_blob
              # asset_id on the previous content blob gets blanked out after the above command is run, so need to do:
              old_content_blob.update_column(:asset_id, existing.id)
              existing.save_as_new_version("Updated to #{version}")
              new_content_blob.save!
              registered << existing.latest_version
            end
          else
            puts "  Version #{existing_version} already registered, doing nothing"
          end
        else
          puts "  Registering new resource"
          if @debug
            resource.valid?
          else
            resource.save
          end

          registered << resource
        end
      end

      registered
    end

    # Build an RO-Crate Zip file from the given ruby-git Git repository, and return the path to it.
    def build_workflow_ro_crate(git)
      crate = read_crate(git)
      crate['softwareVersion'] ||= git.describe(nil, tags: true, abbrev: 0)
      crate['isBasedOn'] ||= git.remote('origin').url
      crate['sdDatePublished'] ||= Time.now
      crate.preview.template ||= WorkflowExtraction::PREVIEW_TEMPLATE
      p = File.join(crate_path, "#{[@organization, Pathname.new(git.dir.path).basename].join('-').gsub('/', '-')}.crate.zip")
      f = File.new(p, 'w')
      puts "  Written to: #{p}"
      ROCrate::Writer.new(crate).write_zip(f)
      File.expand_path(p)
    end

    def read_crate(git)
      ROCrate::WorkflowCrateReader.read_directory(git.dir.path)
    end

    # Get all the repositories in the given org from the GitHub API.
    def list_repositories
      JSON.parse(cached('iwc/repo-list.json') { github["users/#{@organization}/repos?sort=updated&direction=desc"].get.body })
    end

    # Clone the given repositories (from above call), or make sure already-cloned repos are fetched.
    def clone_repositories(repo_list)
      repo_list.map do |repo_info|
        repo = repo_info['full_name']
        full_dest_path = File.expand_path(File.join(git_path, repo))
        if !File.exist?(full_dest_path)
          puts "  Cloning: #{repo}"
          git = Git.clone("https://github.com/#{repo}", repo, path: git_path)
        else
          puts "  Not cloning, directory exists: #{full_dest_path}"
          git = Git.open(full_dest_path)
        end
        puts "  Fetching latest..."
        git.fetch
        git.checkout(@main_branch)
        git.pull('origin', @main_branch)
        tag = git.describe(nil, tags: true, abbrev: 0)
        puts "  Checking out #{tag}"
        git.checkout(tag)
        git
      end
    end

    def github
      RestClient::Resource.new('https://api.github.com', {})
    end

    def git_path
      ::File.join(GIT_DESTINATION, @organization).tap { |x| FileUtils.mkdir_p(x) }
    end

    def crate_path
      ::File.join(CRATE_DESTINATION, @organization).tap { |x| FileUtils.mkdir_p(x) }
    end

    def cache_path
      ::File.join(CACHE_DESTINATION, @organization).tap { |x| FileUtils.mkdir_p(x) }
    end

    def cached(name)
      path = File.expand_path(File.join(cache_path, name.gsub('/', '-')))
      if File.exist?(path)
        File.read(path)
      else
        File.write(path, yield)
        File.read(path)
      end
    end
  end
end
