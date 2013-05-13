require 'test_helper'
require 'time_test_helper'

class SubMailerTest < ActionMailer::TestCase

  test "send digest" do
    p = Factory :person
    p2 = Factory :person
    df = Factory :data_file, :projects=>p.projects
    log = Factory :activity_log,:activity_loggable=>df,:action=>"create",:controller_name=>"data_files",:created_at=>2.hour.ago, :culprit=>p2.user

    email = nil

    now = Time.now

    pretend_now_is(now) do
      email = SubMailer.send_digest_subscription p, [log], 'daily'
    end

    assert_equal "text/html; charset=UTF-8",email.content_type
    assert_equal "UTF-8", email.charset
    assert_equal ["no-reply@sysmo-db.org"], email.from
    assert_equal [p.email], email.to
    assert_equal 'The Sysmo SEEK Subscription Report', email.subject
    assert email.body.include?("Dear #{p.name},")
    assert email.body.include?(%!<td><a href="http://localhost:3000/data_files/#{df.id}">#{df.title}</a></td>!)
    assert email.body.include?(%!<td><a href="http://localhost:3000/people/#{p2.id}">#{p2.name}</a></td>!)
  end

end