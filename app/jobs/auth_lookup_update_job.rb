class AuthLookupUpdateJob < BatchJob
  include CommonSweepers

  queue_as QueueNames::AUTH_LOOKUP
  queue_with_priority 1

  def timelimit
    1.hour
  end

  def follow_on_job?
    AuthLookupUpdateQueue.any?
  end

  private

  def perform_job(item)
    if item.nil?
      update_assets_for_user nil
    elsif item.authorization_supported?
      update_for_each_user item
    elsif item.is_a?(User)
      update_assets_for_user item
    elsif item.is_a?(Person)
      update_assets_for_user item.user unless item.user.nil?
    else
      Rails.logger.error("Unexpected type encountered: #{item.class.name}")
    end

    # required to make sure that cached fragments that contain details related to authorization are regenerated after the job has run
    expire_auth_related_fragments
  end

  def gather_items
    AuthLookupUpdateQueue.dequeue(Seek::Config.auth_lookup_update_batch_size)
  end

  def update_for_each_user(item)
    item.update_lookup_table_for_all_users
  end

  # spawns a new UserAuthLookupUpdateJob for the user and each type
  def update_assets_for_user(user)
    Seek::Util.authorized_types.each do |type|
      UserAuthLookupUpdateJob.perform_later(user, type.name)
    end
  end
end
