class AuthLookupUpdateJob

  @@my_yaml = AuthLookupUpdateJob.new.to_yaml

  def perform
    todo = AuthLookupUpdateQueue.all.collect do |queued|
      todo = queued.item
      queued.destroy
      todo
    end
    todo.uniq.each do |item|
      if item.authorization_supported?
        update_for_each_user item
      elsif item.is_a?(User)
        update_assets_for_user item
      elsif item.is_a?(Person)
        update_assets_for_user item.user unless item.user.nil?
      else
        #should never get here
        Delayed::Job.logger.error("Unexecpted type encountered: #{item.class.name}")
      end
    end
  end

  def update_for_each_user item
    item.update_lookup_table(nil)
    User.all.each do |user|
      item.update_lookup_table(user)
    end
  end

  def update_assets_for_user user
    Seek::Util.authorized_types.each do |type|
      type.all.each do |item|
          item.update_lookup_table(user)
      end
    end
  end

  def self.add_items_to_queue items, t=5.seconds.from_now
    items = Array(items)
    disable_authorization_checks do
      items.each do |item|
        AuthLookupUpdateQueue.create :item=>item
      end
      Rails.logger.warn "#{AuthLookupUpdateQueue.count} items in AuthLookupUpdateQueue"
      Delayed::Job.enqueue(AuthLookupUpdateJob.new,0,t) unless AuthLookupUpdateJob.exists?
    end
  end

  def self.exists?
    Delayed::Job.find(:first,:conditions=>['handler = ? AND locked_at IS ?',@@my_yaml,nil]) != nil
  end

  
end