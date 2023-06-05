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
          project = Scrapers::Util.bot_project(title: 'iwc')
          assert_equal 'iwc', project.title
          assert_includes project.people, Scrapers::Util.bot_account
        end
      end
    end

    assert_no_difference('Project.count') do
      assert_no_difference('Person.count') do
        assert_no_difference('Institution.count') do
          project = Scrapers::Util.bot_project(title: 'iwc')
          assert_equal 'iwc', project.title
        end
      end
    end

    assert_difference('Project.count', 1) do
      assert_no_difference('Person.count') do
        assert_no_difference('Institution.count') do
          project = Scrapers::Util.bot_project(title: 'Another Project')
          assert_equal 'Another Project', project.title
          assert_includes project.people, Scrapers::Util.bot_account
        end
      end
    end
  end
end
