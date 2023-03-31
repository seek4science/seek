module Scrapers
  class IwcScraper < GithubScraper

    private

    # Filter repositories to only register repos with .dockstore.yml present.
    def list_repositories
      return static_list_repositories if false
      super.select do |repo|
        sleep 1
        begin
          github["repos/#{repo['full_name']}/contents/.dockstore.yml"].head
          sleep 1
        rescue RestClient::NotFound
          output.puts "No .dockstore.yml found in #{repo['full_name']}, skipping"
        end
      end
    end

    # To avoid hitting GitHub API rate limit
    def static_list_repositories
      %w[https://github.com/iwc-workflows/sars-cov-2-variation-reporting.git
         https://github.com/iwc-workflows/sars-cov-2-pe-illumina-artic-variant-calling.git
         https://github.com/iwc-workflows/sars-cov-2-ont-artic-variant-calling.git
         https://github.com/iwc-workflows/sars-cov-2-se-illumina-wgs-variant-calling.git
         https://github.com/iwc-workflows/sars-cov-2-pe-illumina-wgs-variant-calling.git
         https://github.com/iwc-workflows/parallel-accession-download.git
         https://github.com/iwc-workflows/sars-cov-2-consensus-from-variation.git
         https://github.com/iwc-workflows/sars-cov-2-pe-illumina-artic-ivar-analysis.git
         https://github.com/iwc-workflows/fragment-based-docking-scoring.git
         https://github.com/iwc-workflows/protein-ligand-complex-parameterization.git
         https://github.com/iwc-workflows/gromacs-mmgbsa.git
         https://github.com/iwc-workflows/gromacs-dctmd.git].map { |r| { 'clone_url' => r }}
    end
  end
end