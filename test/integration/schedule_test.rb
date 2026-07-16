require 'test_helper'

class ScheduleTest < ActionDispatch::IntegrationTest
  setup do
    @schedule = Whenever::Test::Schedule.new(file: 'config/schedule.rb')
  end

  test 'should read schedule file' do
    rake_jobs = @schedule.jobs[:rake]

    sitemap = pop_task(rake_jobs, '-s sitemap:refresh')
    assert sitemap
    assert_equal [1.day, { at: '12:45 am' }], sitemap[:every]

    sessions_trim = pop_task(rake_jobs, 'db:sessions:batch_trim')
    assert sessions_trim
    assert_equal [1.day, { at: '1:15 am' }], sessions_trim[:every]

    assert_empty rake_jobs, 'Found untested rake job(s) in schedule'

    # Everything that's an ActiveJob enqueue or a plain Ruby method call belongs in
    # config/recurring.yml (see RecurringTest), not here - this guards against a repeat
    # of the bug found in #2656 where entries were added to recurring.yml but never
    # removed from here, so they ran twice (once via cron, once via Solid Queue).
    assert_empty @schedule.jobs[:runner], 'config/schedule.rb should have no runner jobs - ' \
      'move ActiveJob/plain-Ruby entries to config/recurring.yml instead'
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
