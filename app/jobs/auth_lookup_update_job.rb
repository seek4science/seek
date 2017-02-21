class AuthLookupUpdateJob < SeekJob
  def add_items_to_queue(items, time = default_delay.from_now, priority = 0, queuepriority = default_priority)
    if Seek::Config.auth_lookup_enabled

      #needs to retain any nil items, which Array(items) would remove
      items = [items].flatten

      disable_authorization_checks do
        items.uniq.each do |item|
          add_item_to_queue(item, queuepriority)
        end
        queue_job(priority, time)
      end
    end
  end

  def queue_name
    QueueNames::AUTH_LOOKUP
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
      Delayed::Job.logger.error("Unexpected type encountered: #{item.class.name}")
    end

    # required to make sure that cached fragments that contain details related to authorization are regenerated after the job has run
    expire_auth_related_fragments
  end

  def retry_item(item)
    add_items_to_queue(item, 15.seconds.from_now, 1)
  end

  def gather_items
    # including item_type in the order, encourages assets to be processed before users (since they are much quicker), due to the happy coincidence
    # that User falls last alphabetically. Its not that important if a new authorized type is added after User in the future.
    AuthLookupUpdateQueue.order('priority,item_type,id').limit(Seek::Config.auth_lookup_update_batch_size).collect do |queued|
      take_queued_item(queued)
    end.uniq.compact
  end

  def update_for_each_user(item)
    item.update_lookup_table_for_all_users
  end

  def update_assets_for_user(user)
    User.transaction(requires_new: :true) do
      Seek::Util.authorized_types.each do |type|
        type.find_each do |item|
          item.update_lookup_table(user)
        end
      end
    end
    GC.start
  end

  def follow_on_job?
    AuthLookupUpdateQueue.count > 0 && !exists?
  end

  def follow_on_priority
    0
  end

  def follow_on_delay
    0.seconds
  end

  def add_item_to_queue(item, queuepriority)
    # immediately update for the current user and anonymous user
    if item.respond_to?(:authorization_supported?) && item.authorization_supported?
      item.update_lookup_table(User.current_user)
      item.update_lookup_table(nil) unless User.current_user.nil?
    end
    # Could potentially delete the records for this item (either by asset_id or user_id) to ensure an immediate reflection of the change,
    # but with some slowdown until the changes have been reapplied.
    # for assets its simply - item.remove_from_lookup_table
    # for users some additional simple code is required.
    AuthLookupUpdateQueue.create(item: item, priority: queuepriority) unless AuthLookupUpdateQueue.exists?(item)
  end
end
