require 'rest-client'
require 'json'
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

        puts "Creating resources"
        resources = create_resources(repositories)

        successes, failures = resources.partition(&:persisted?)

        if successes.any?
          puts "Registered:"
          successes.each { |w| puts " * #{w} - #{w.title}" }
        end

        if failures.any?
          puts "Not registered#{@debug ? ' (DEBUG MODE)' : ''}:"
          failures.each do |w|
            puts " * #{w.title}"
            w.errors.full_messages.each { |e| puts "     #{e}" }
          end
        end

        resources
      end
    end

    private

    # If the resource has already been registered, find it.
    def existing_resource(repo)
      @project.workflows.joins(:source_link).where(asset_links: { url: repo.remote.chomp('.git') }).first
    end

    def create_resources(repositories)
      repositories.map do |repo|
        puts "  Considering #{repo.remote.chomp('.git')}..."
        latest_tag = `cd #{repo.git_base.path}/.. && git describe --tags --abbrev=0 remotes/origin/#{@main_branch}`.chomp
        wiz = GitWorkflowWizard.new(params: {
          git_version_attributes: {
            git_repository_id: repo.id,
            ref: "refs/tags/#{latest_tag}",
            name: latest_tag,
            comment: "Updated to #{latest_tag}"
          }
        })
        workflow = existing_resource(repo)
        new_version = false
        if workflow
          new_version = true
          wiz.workflow = workflow
          unless workflow.git_versions.none? { |gv| gv.name == latest_tag }
            puts "    Version #{latest_tag} already registered, doing nothing"
            next
          end
          puts "    New version detected! (#{latest_tag}), creating new version"
        else
          puts "    Creating new workflow"
        end

        workflow = wiz.run
        if wiz.next_step == :provide_metadata
          workflow.contributor = @contributor
          workflow.projects = Array(@project)
          workflow.policy = Policy.projects_policy(workflow.projects)
          workflow.policy.access_type = Policy::ACCESSIBLE
          workflow.source_link_url = repo.remote.chomp('.git')
          unless @debug
            if new_version
              workflow.git_version.resource_attributes = workflow.attributes
              workflow.git_version.save
            end
            workflow.git_versions.reset
            workflow.save
          end
        end

        workflow
      end.compact
    end

    # Get all the repositories in the given org from the GitHub API.
    def list_repositories
      JSON.parse(github["users/#{@organization}/repos?sort=updated&direction=desc"].get.body)
    end

    # Clone the given repositories (from above call), or make sure already-cloned repos are fetched.
    def clone_repositories(repo_list)
      repos = repo_list.map { |repo| Git::Repository.find_or_create_by(remote: repo['clone_url']) }

      repos.each(&:fetch)

      repos
    end

    def github
      RestClient::Resource.new('https://api.github.com', {})
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
