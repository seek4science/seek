require 'test_helper'

class SubMailerTest < ActionMailer::TestCase

  test 'send digest' do
    p = Factory :person
    p2 = Factory :person
    df = Factory :data_file, projects: p.projects, contributor:p
    model = Factory :model, projects: p.projects, contributor: p

    log = Factory :activity_log, activity_loggable: df, action: 'create', controller_name: 'data_files', created_at: 2.hour.ago, culprit: p2.user

    dateForPastLog = DateTime.new(2012, 12, 25, 13, 15, 0)
    log2 = Factory :activity_log, activity_loggable: model, action: 'update', controller_name: 'data_files', created_at: dateForPastLog, culprit: p2.user
    email = nil

    now = Time.now.in_time_zone('UTC')

    travel_to(now) do
      email = SubMailer.send_digest_subscription p, [log, log2], 'daily'
    end

    assert_equal 'text/html; charset=UTF-8', email.content_type
    assert_equal 'UTF-8', email.charset
    assert_equal ['no-reply@sysmo-db.org'], email.from
    assert_equal [p.email], email.to
    assert_equal 'The Sysmo SEEK Subscription Report', email.subject
    assert email.body.include?("Dear #{p.name},")
    assert email.body.include?(%(<td><a href="http://localhost:3000/data_files/#{df.id}">#{df.title}</a></td>))
    assert email.body.include?(%(<td><a href="http://localhost:3000/people/#{p2.id}">#{p2.name}</a></td>))
    assert email.body.include?('following resources have been created or updated')
    assert email.body.include?('Resources Created:')
    assert email.body.include?('Resources Updated:')
    assert email.body.include?('Date Created')
    assert email.body.include?('Date Updated')

    expectedDate = dateForPastLog.localtime.strftime("#{dateForPastLog.day.ordinalize} %b %Y")
    expectedDate = dateForPastLog.localtime.strftime("#{expectedDate} at %H:%M")

    assert email.body.include?(expectedDate)
  end

  test 'send immediate email' do
    p = Factory :person
    p2 = Factory :person
    df = Factory :data_file, projects: p.projects, contributor:p
    log = Factory :activity_log, activity_loggable: df, action: 'create', controller_name: 'data_files', created_at: 2.hour.ago, culprit: p2.user

    email = nil

    now = Time.now
    travel_to(now) do
      email = SubMailer.send_immediate_subscription p, log
    end
    assert_not_nil email
    assert_equal 'text/html; charset=UTF-8', email.content_type
    assert_equal 'UTF-8', email.charset
    assert_equal ['no-reply@sysmo-db.org'], email.from
    assert_equal [p.email], email.to
    assert_equal 'The Sysmo SEEK Subscription Report', email.subject
    assert email.body.include?("Dear #{p.name},")
    assert email.body.include?(%(<td><a href="http://localhost:3000/data_files/#{df.id}">#{df.title}</a></td>))
    assert email.body.include?(%(<td><a href="http://localhost:3000/people/#{p2.id}">#{p2.name}</a></td>))
    assert email.body.include?('following resources have just been created or updated in')
    assert email.body.include?('Resources Created:')
  end
end
