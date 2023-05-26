require 'test_helper'
require 'minitest/mock'

class GithubScraperTest < ActionDispatch::IntegrationTest
  test 'can scrape a new workflow' do
    project = Scrapers::Util.bot_project(title: 'test')
    bot = Scrapers::Util.bot_account
    scraper = Scrapers::GithubScraper.new('test-123', project, bot, main_branch: 'master', output: StringIO.new)

    repos = [FactoryBot.create(:remote_workflow_ro_crate_repository, remote: 'https://not.real.url/repo.git')]

    scraper.stub(:list_repositories, -> () { repos.map { |r| { 'clone_url' => r.remote } } }) do
      scraper.stub(:clone_repositories, -> (_) { repos }) do
        assert_difference('Workflow.count', 1) do
          assert_difference('Workflow::Git::Version.count', 1) do
            assert_difference('Git::Annotation.count', 1) do
              assert_no_difference('Git::Repository.count') do
                scraped = scraper.scrape
                wf = scraped.first
                assert_equal bot, wf.contributor
                assert_equal [project], wf.projects
                assert_equal 'sort-and-change-case', wf.title
                assert_equal 'sort lines and change text to upper case', wf.description
                assert_equal 'Apache-2.0', wf.license
                assert_equal 'sort-and-change-case.ga', wf.main_workflow_path
                assert_equal 'v0.02', wf.git_version.name
              end
            end
          end
        end
      end
    end
  end

  test 'can scrape a new version of a workflow' do
    project = Scrapers::Util.bot_project(title: 'test')
    bot = Scrapers::Util.bot_account
    scraper = Scrapers::GithubScraper.new('test-123', project, bot, main_branch: 'master', output: StringIO.new)

    repos = [FactoryBot.create(:remote_workflow_ro_crate_repository, remote: 'https://not.real.url/repo.git')]

    existing = FactoryBot.create(:ro_crate_git_workflow,
                       contributor: bot,
                       projects: [project],
                       source_link_url: 'https://not.real.url/repo',
                       git_version_attributes: { name: 'v0.01',
                                                 git_repository_id: repos.first.id,
                                                 ref: 'refs/tags/v0.01',
                                                 commit: 'a321b6e',
                                                 main_workflow_path: 'sort-and-change-case.ga',
                                                 mutable: false })

    scraper.stub(:list_repositories, -> () { repos.map { |r| { 'clone_url' => r.remote } } }) do
      scraper.stub(:clone_repositories, -> (_) { repos }) do
        assert_no_difference('Workflow.count') do
          assert_difference('Workflow::Git::Version.count', 1) do
            assert_difference('Git::Annotation.count', 1) do
              assert_no_difference('Git::Repository.count') do
                scraped = scraper.scrape
                wf = scraped.first
                assert_equal 2, existing.reload.git_versions.count
                assert_equal existing, wf
                assert_equal bot, wf.contributor
                assert_equal [project], wf.projects
                assert_equal 'sort-and-change-case', wf.title
                assert_equal 'sort lines and change text to upper case', wf.description
                assert_equal 'Apache-2.0', wf.license
                assert_equal 'sort-and-change-case.ga', wf.main_workflow_path
                assert_equal 'v0.02', wf.git_version.name
              end
            end
          end
        end
      end
    end
  end

  test 'does not register duplicates' do
    project = Scrapers::Util.bot_project(title: 'test')
    bot = Scrapers::Util.bot_account
    scraper = Scrapers::GithubScraper.new('test-123', project, bot, main_branch: 'master', output: StringIO.new)

    repos = [FactoryBot.create(:remote_workflow_ro_crate_repository, remote: 'https://not.real.url/repo.git')]

    existing = FactoryBot.create(:ro_crate_git_workflow,
                       contributor: bot,
                       projects: [project],
                       source_link_url: 'https://not.real.url/repo',
                       git_version_attributes: { name: 'v0.02',
                                                 git_repository_id: repos.first.id,
                                                 ref: 'refs/tags/v0.02',
                                                 commit: '20eabdc',
                                                 main_workflow_path: 'sort-and-change-case.ga',
                                                 mutable: false })

    scraper.stub(:list_repositories, -> () { repos.map { |r| { 'clone_url' => r.remote } } }) do
      scraper.stub(:clone_repositories, -> (_) { repos }) do
        assert_no_difference('Workflow.count') do
          assert_no_difference('Workflow::Git::Version.count') do
            assert_no_difference('Git::Annotation.count') do
              assert_no_difference('Git::Repository.count') do
                scraped = scraper.scrape
                assert scraped.empty?
              end
            end
          end
        end
      end
    end
  end

  private

  def login_as(user)
    User.current_user = user
    post '/session', params: { login: user.login, password: generate_user_password }
  end
end