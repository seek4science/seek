require 'test_helper'
require 'minitest/mock'

class GithubScraperTest < ActionDispatch::IntegrationTest
  test 'can scrape a new workflow' do
    project = Scrapers::Util.bot_project(title: 'test')
    bot = Scrapers::Util.bot_account
    project_admin = FactoryBot.create(:project_administrator)
    disable_authorization_checks do
      project.default_policy = FactoryBot.create(:private_policy)
      project.default_policy.permissions << Permission.new(contributor: project, access_type: Policy::EDITING)
      project.default_policy.permissions << Permission.new(contributor: project_admin, access_type: Policy::MANAGING)
      project.default_policy.save!
      project.use_default_policy = true
      project.save!
    end
    scraper = Scrapers::GithubScraper.new(project, bot, organization: 'test-123', main_branch: 'master', output: StringIO.new)

    repos = [FactoryBot.create(:remote_workflow_ro_crate_repository, remote: 'https://github.com/crs4/sort-and-change-case-workflow.git')]

    VCR.use_cassette('github/fetch_topics') do
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
                  assert_equal ['case', 'sort'], wf.tags.sort
                  assert_equal Policy::NO_ACCESS, wf.policy.access_type
                  assert_equal 2, wf.policy.permissions.count
                  assert wf.policy.permissions.detect { |p| p.contributor == project_admin && p.access_type == Policy::MANAGING }
                  assert wf.policy.permissions.detect { |p| p.contributor == project && p.access_type == Policy::EDITING }
                end
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
    scraper = Scrapers::GithubScraper.new(project, bot, organization: 'test-123', main_branch: 'master', output: StringIO.new)

    repos = [FactoryBot.create(:remote_workflow_ro_crate_repository, remote: 'https://github.com/crs4/sort-and-change-case-workflow.git')]

    existing = FactoryBot.create(:ro_crate_git_workflow,
                                 contributor: bot,
                                 projects: [project],
                                 source_link_url: 'https://github.com/crs4/sort-and-change-case-workflow',
                                 git_version_attributes: { name: 'v0.01',
                                                           git_repository_id: repos.first.id,
                                                           ref: 'refs/tags/v0.01',
                                                           commit: 'a321b6e4dd2cfb5219cf03bb9e2743db344f537a',
                                                           main_workflow_path: 'sort-and-change-case.ga',
                                                           mutable: false })

    VCR.use_cassette('github/fetch_topics') do
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
  end

  test 'does not register duplicates' do
    project = Scrapers::Util.bot_project(title: 'test')
    bot = Scrapers::Util.bot_account
    scraper = Scrapers::GithubScraper.new(project, bot, organization: 'test-123', main_branch: 'master', output: StringIO.new)

    repos = [FactoryBot.create(:remote_workflow_ro_crate_repository, remote: 'https://github.com/crs4/sort-and-change-case-workflow.git')]

    existing = FactoryBot.create(:ro_crate_git_workflow,
                                 contributor: bot,
                                 projects: [project],
                                 source_link_url: 'https://github.com/crs4/sort-and-change-case-workflow',
                                 git_version_attributes: { name: 'v0.02',
                                                           git_repository_id: repos.first.id,
                                                           ref: 'refs/tags/v0.02',
                                                           commit: '20eabdc',
                                                           main_workflow_path: 'sort-and-change-case.ga',
                                                           mutable: false })

    VCR.use_cassette('github/fetch_topics') do
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
  end

  test 'tags are ordered oldest -> newest when scraping all' do
    project = Scrapers::Util.bot_project(title: 'test')
    bot = Scrapers::Util.bot_account
    scraper = Scrapers::GithubScraper.new(project, bot, organization: 'test-123', output: StringIO.new, only_latest: false)
    repo = FactoryBot.create(:nfcore_remote_repository)

    assert_equal %w[1.0 1.1 1.2 1.3 1.4 1.4.1 1.4.2 2.0 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.8.1 3.9 3.10 3.10.1
                        3.11.0 3.11.1 3.11.2 3.12.0 3.13.0 3.13.1 3.13.2 3.14.0], scraper.send(:all_tags, repo)
  end

  private

  def login_as(user)
    User.current_user = user
    post '/session', params: { login: user.login, password: generate_user_password }
  end
end