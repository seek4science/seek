require 'test_helper'

class TavernaPlayerRunTest < ActiveSupport::TestCase
  test 'can create' do
    run = Factory(:taverna_player_run, projects: [Factory(:project)])

    assert run.save
  end

  test 'project is saved' do
    project = Factory(:project)
    run = Factory(:taverna_player_run, projects: [project])

    assert_equal [project], TavernaPlayer::Run.find(run.id).projects
  end
end
