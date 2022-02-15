module Scrapers
  class IwcScraper < GithubScraper

    private

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