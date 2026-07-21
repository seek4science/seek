require 'test_helper'

class ScheduleTest < ActionDispatch::IntegrationTest
  setup do
    @schedule = Whenever::Test::Schedule.new(file: 'config/schedule.rb')
  end

  test 'schedule file defines no application jobs - those live in config/recurring.yml' do
    # All periodic application work moved to config/recurring.yml (see RecurringTest). Only OS-level
    # shell maintenance remains here, so there should be no rake or runner jobs. This also guards
    # against a repeat of the #2656 bug where entries were added to recurring.yml but left here too,
    # running twice (once via cron, once via Solid Queue).
    assert_empty @schedule.jobs[:rake], 'config/schedule.rb should have no rake jobs'
    assert_empty @schedule.jobs[:runner], 'config/schedule.rb should have no runner jobs'

    # The only remaining entry is the Docker-only soffice reaper, which is not scheduled outside
    # Docker.
    assert_empty @schedule.jobs[:command], 'config/schedule.rb should schedule no commands outside Docker'
  end

  test 'kill-long-running-soffice command is only scheduled when using docker' do
    refute Seek::Docker.using_docker?
    assert_empty @schedule.jobs[:command]

    docker_flag_path = Seek::Docker::FLAG_FILE_PATH
    begin
      FileUtils.touch(docker_flag_path)
      docker_schedule = Whenever::Test::Schedule.new(file: 'config/schedule.rb')
      soffice = pop_task(docker_schedule.jobs[:command], 'sh /seek/script/kill-long-running-soffice.sh')
      assert soffice
      assert_equal [10.minutes], soffice[:every]

      # still no application jobs, even under docker
      assert_empty docker_schedule.jobs[:rake], 'config/schedule.rb should have no rake jobs under docker'
      assert_empty docker_schedule.jobs[:runner], 'config/schedule.rb should have no runner jobs under docker'
    ensure
      File.delete(docker_flag_path) if File.exist?(docker_flag_path)
    end
  end

  private

  def pop_task(runners, task)
    i = runners.index { |job| job[:task] == task }
    return runners.delete_at(i) if i

    nil
  end
end
