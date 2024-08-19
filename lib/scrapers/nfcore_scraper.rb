module Scrapers
  class NfcoreScraper < GithubScraper

    private

    def list_repositories
      repos = JSON.parse(RestClient.get('https://nf-co.re/pipelines.json'))['remote_workflows']
      repos.reject! { |r| r['archived'] || r['disabled'] }
      @nfcore_pipelines = {} # Store repo metadata from pipelines.json to fetch main branch name and topics later
      repos.each do |r|
        r['clone_url'] = "https://github.com/#{r['full_name']}.git"
        @nfcore_pipelines[r['clone_url']] = r
      end

      repos
    end

    def main_branch(repo)
      @nfcore_pipelines.dig(repo.remote, 'default_branch') || super
    end

    def topics(repo)
      @nfcore_pipelines.dig(repo.remote, 'topics') || []
    end

    def latest_tag(repo)
      all_tags(repo).last
    end

    def all_tags(repo)
      (@nfcore_pipelines.dig(repo.remote, 'releases') || []).sort_by { |t| Date.parse(t['published_at']) }.map { |t| t['tag_name'] } - ['dev']
    end

    def workflow_wizard(repo, tag)
      GitWorkflowWizard.new(workflow_class: WorkflowClass.find_by_key('nextflow'),
        params: {
        git_version_attributes: {
          main_workflow_path: 'nextflow.config',
          git_repository_id: repo.id,
          ref: "refs/tags/#{tag}",
          name: tag,
          comment: "Updated to #{tag}"
        }
      })
    end
  end
end