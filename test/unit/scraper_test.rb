require 'test_helper'

class ScraperTest < ActiveSupport::TestCase
  def setup
    @person = FactoryBot.create(:person)
    @project = @person.projects.first
    @project_ids = [@project.id]
  end

  test 'can create or re-use an account for the scraper bot' do
    disable_authorization_checks { Person.where(last_name: 'Bot').destroy_all }

    refute Person.where(last_name: 'Bot').exists?

    acc = nil
    assert_difference('Person.count', 1) do
      acc = Scrapers::Util.bot_account
    end

    assert Person.where(last_name: 'Bot').exists?

    assert_no_difference('Person.count') do
      acc2 = Scrapers::Util.bot_account
      assert_equal acc, acc2
    end
  end

  test 'can create or re-use a project for the scraper bot, and add them as a member' do
    assert_difference('Project.count', 1) do
      assert_difference('Person.count', 1) do
        assert_difference('Institution.count', 1) do
          assert_difference('GroupMembership.count', 1) do
            project = Scrapers::Util.bot_project(title: 'iwc')
            assert_equal 'iwc', project.title
            assert_includes project.people, Scrapers::Util.bot_account
          end
        end
      end
    end

    assert_no_difference('Project.count') do
      assert_no_difference('Person.count') do
        assert_no_difference('Institution.count') do
          assert_no_difference('GroupMembership.count') do
            project = Scrapers::Util.bot_project(title: 'iwc')
            assert_equal 'iwc', project.title
          end
        end
      end
    end

    assert_difference('Project.count', 1) do
      assert_no_difference('Person.count') do
        assert_no_difference('Institution.count') do
          assert_difference('GroupMembership.count', 1) do
            project = Scrapers::Util.bot_project(title: 'Another Project')
            assert_equal 'Another Project', project.title
            assert_includes project.people, Scrapers::Util.bot_account
          end
        end
      end
    end

    # Add to existing project
    FactoryBot.create(:project, title: 'An existing project 123')
    assert_no_difference('Project.count') do
      assert_no_difference('Person.count') do
        assert_no_difference('Institution.count') do
          assert_difference('GroupMembership.count', 1) do
            project = Scrapers::Util.bot_project(title: 'An existing project 123')
            assert_equal 'An existing project 123', project.title
            assert_includes project.people, Scrapers::Util.bot_account
          end
        end
      end
    end
  end

  test 'scrape from config' do
    # Make sure no repositories are listed so no actual import occurs
    stub_request(:get, 'https://nf-co.re/pipelines.json')
      .to_return(body: '{ "remote_workflows" : [] }', status: 200)
    stub_request(:get, 'https://api.github.com/users/iwc-workflows/repos?direction=desc&sort=updated')
      .to_return(body: '[]', status: 200)

    out = StringIO.new
    err = StringIO.new
    Scrapers::Util.scrape(output: out, error_output: err)
    out.rewind
    err.rewind

    output = out.read
    assert_includes output, 'Running 2 scrapers:'
    assert_includes output, 'Succeeded: 2'
    assert_includes output, 'Failed: 0'
    assert_empty err.read
  end


  test 'scraping logs error and continues with other scrapers' do
    # Make sure no repositories are listed so no actual import occurs
    stub_request(:get, 'https://api.github.com/users/custom-org/repos?direction=desc&sort=updated')
      .to_return(body: '[]', status: 200)

    class Scrapers::DoNothingScraper
      def initialize(p, c, output: STDOUT, custom_option:)
        @output = output
        @custom_option = custom_option
      end
      def scrape
        @output.puts "I'm outputting: #{@custom_option}"
      end
    end

    scraper_config = [
      {
        project_title: 'test-456',
        class: 'BadScraper' # Missing class
      },
      {
        project_title: 'test-789',
        class: 'DoNothingScraper',
        options: {
          custom_option: 'banana',
        }
      },
      {
        project_title: 'test-123',
        class: 'GithubScraper',
        options: {
          organization: 'custom-org',
        }
      },
      { } # No config
    ]

    out = StringIO.new
    err = StringIO.new
    with_config_value(:scraper_config, scraper_config) do
      Scrapers::Util.scrape(output: out, error_output: err)
    end
    out.rewind
    err.rewind

    output = out.read
    assert_includes output, 'Running 4 scrapers:'
    assert_includes output, "I'm outputting: banana"
    assert_includes output, 'Succeeded: 2'
    assert_includes output, 'Failed: 2'
    out.rewind
    error = err.read
    assert_includes error, 'test-456 failed: NameError - uninitialized constant Scrapers::BadScraper'
    assert_includes error, "<scraper with no project title> failed: RuntimeError - Missing 'project_title'"
  end
end
