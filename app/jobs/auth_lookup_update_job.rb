class AuthLookupUpdateJob

  @@my_yaml = AuthLookupUpdateJob.new.to_yaml

  BATCHSIZE=10

  def perform
    process_queue

    if AuthLookupUpdateQueue.count>0 && !AuthLookupUpdateJob.exists?
      Delayed::Job.enqueue(AuthLookupUpdateJob.new,0,1.seconds.from_now)
    end
  end

  def process_queue
    todo = AuthLookupUpdateQueue.all(:limit=>BATCHSIZE,:order=>:priorty).collect do |queued|
      todo = queued.item
      queued.destroy
      todo
    end
    todo.uniq.each do |item|
      begin
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
      rescue Exception=>e
        AuthLookupUpdateQueue.add_items_to_queue(item)
      end
    end
  end

  def update_for_each_user item
    User.transaction(:requires_new=>:true) do
       item.update_lookup_table(nil)
      User.all.each do |user|
        item.update_lookup_table(user)
      end
    end
    GC.start
  end

  def update_assets_for_user user
    User.transaction(:requires_new=>:true) do
      Seek::Util.authorized_types.each do |type|
        type.all.each do |item|
            item.update_lookup_table(user)
        end
      end
    end
    GC.start
  end

  def self.add_items_to_queue items, t=5.seconds.from_now,priority=0
    items = Array(items)
    disable_authorization_checks do
      items.uniq.each do |item|
        #immediately update for the current user
        if item.authorization_supported?
          item.update_lookup_table(User.current_user)
        end
        AuthLookupUpdateQueue.create :item=>item,:priority=>priority
      end
      Rails.logger.warn "#{AuthLookupUpdateQueue.count} items in AuthLookupUpdateQueue"
      Delayed::Job.enqueue(AuthLookupUpdateJob.new,0,t) unless AuthLookupUpdateJob.exists?
    end
  end

  def self.exists?
    Delayed::Job.find(:first,:conditions=>['handler = ? AND locked_at IS ?',@@my_yaml,nil]) != nil
  end

  
end