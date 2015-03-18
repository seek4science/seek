class SendPeriodicEmailsJob < SeekJob

  DELAYS = {'daily' => 1.day, 'weekly' => 1.week, 'monthly' => 1.month}

  Subscription::FREQUENCIES.drop(1).each do |frequency|
    eval <<-END_EVAL
    def self.#{frequency}_exists?
      SendPeriodicEmailsJob.new('#{frequency}').exists?
    end
    END_EVAL
  end

  attr_reader :frequency

  def initialize frequency
    @frequency = frequency.to_s.downcase
    raise Exception.new("invalid frequency - #{frequency}") unless DELAYS.keys.include?(@frequency)
  end

  def before(job)
    #make sure the SMTP,site_base_host configuration is in sync with current SEEK settings
    Seek::Config.smtp_propagate
    Seek::Config.site_base_host_propagate
  end

  def perform_job item
    logs = activity_logs_since delay_for_frequency.ago
    send_subscription_mails logs
  end

  def gather_items
    [nil]
  end

  def follow_on_job?
    true
  end

  def default_priority
    3
  end

  def follow_on_priority
    1
  end

  def follow_on_delay
    delay_for_frequency
  end

  def allow_duplicate_jobs
    false
  end

  def delay_for_frequency
    DELAYS[frequency]
  end

  def exists? ignore_locked=false
    super(ignore_locked)
  end

  def count ignore_locked=false
    super(ignore_locked)
  end

  def send_subscription_mails logs
    if Seek::Config.email_enabled
      #strip the logs down to those that are relevant
      logs.reject! do |log|
        log.activity_loggable.nil? || !log.activity_loggable.subscribable?
      end

      subscribed_people(logs).each do |person|
        begin
          collect_and_deliver(logs, person)
        rescue Exception => e
          Delayed::Job.logger.error("Error sending subscription emails to person #{person.id} - #{e.message}")
        end
      end
    end
  end

  def collect_and_deliver(logs, person)

    activity_logs = collect_relevant_logs(logs, person)
    SubMailer.send_digest_subscription(person, activity_logs, frequency).deliver if activity_logs.any?
  end

  def collect_relevant_logs(logs, person)
    #get only the logs for items that are visible to this person
    logs_for_visible_items = logs.select { |log| log.activity_loggable.try(:can_view?, person.user) }

    #get the logs for this persons subscribable items, where the subscription has the correct frequency
    activity_logs = logs_for_visible_items.select do |log|
      !person.subscriptions.for_subscribable(log.activity_loggable).select do |subscription|
        subscription.frequency == frequency
      end.empty?
    end
  end

  #limit to only the people subscribed to the items logged, and those that are set to receive notifications and are project members
  def subscribed_people(logs)
    people = people_subscribed_to_logged_items logs
    people.reject! { |person| !person.receive_notifications? }
    people
  end

  #returns an enumaration of the people subscribed to the items in the logs
  def people_subscribed_to_logged_items logs
    items = logs.collect { |log| log.activity_loggable }.uniq
    items.collect do |item|
      subscriptions = Subscription.find_all_by_subscribable_type_and_subscribable_id(item.class.name, item.id)
      subscriptions.collect { |sub| sub.person }
    end.flatten.compact.uniq
  end

  def activity_logs_since time_point
    ActivityLog.where(['created_at>=? and action in (?) and controller_name!=?', time_point, ['create', 'update'], 'sessions'])
  end

  # puts the initial jobs on the queue for each period - daily, weekly, monthly - if they do not exist already
  # starting at midday
  def self.create_initial_jobs
    t=Time.now
    # start tomorrow if time now is later than midday
    t = t + 1.day if t > Time.local_time(t.year, t.month, t.day, 12, 00, 00)
    SendPeriodicEmailsJob.new('daily').create_job(default_priority, Time.local_time(t.year, t.month, t.day, 12, 00, 00))
    SendPeriodicEmailsJob.new('weekly').create_job(default_priority, Time.local_time(t.year, t.month, t.day, 12, 05, 00))
    SendPeriodicEmailsJob.new('monthly').create_job(default_priority, Time.local_time(t.year, t.month, t.day, 12, 10, 00))

  end

  def self.default_priority
    SendPeriodicEmailsJob.new('daily').send(:default_priority)
  end


end
