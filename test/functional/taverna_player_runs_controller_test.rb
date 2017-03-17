require 'test_helper'

class TavernaPlayerRunsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    @controller = TavernaPlayer::RunsController.new
  end

  test 'sends email when failure reported' do
    run = Factory(:failed_run)

    login_as run.contributor

    assert run.reportable?
    assert !run.reported

    assert_emails 1 do
      post :report_problem, id: run.id
    end

    assert_redirected_to run_path(run)
    assert assigns(:run).reported
  end
end
