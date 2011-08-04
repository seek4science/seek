module ActsAsTrashable
  
  def self.included (base)
    base.extend(ActsMethods)
  end
  
  module ActsMethods
    # Class method that injects the trash behavior into the class.
    def acts_as_trashable
      extend ClassMethods
      include InstanceMethods
      before_destroy :store_trash
    end
  end
  
  module ClassMethods
    # Empty the trash for this class of all entries older than the specified maximum age in seconds.
    def empty_trash (max_age)
      TrashRecord.empty_trash(max_age, :only => self)
    end
    
    # Restore a particular entry by id from the trash into an object in memory. The record will not be saved.
    def restore_trash (id)
      trash = TrashRecord.find_trash(self, id)
      return trash.restore if trash
    end
    
    # Restore a particular entry by id from the trash, save it, and delete the trash entry.
    def restore_trash! (id)
      trash = TrashRecord.find_trash(self, id)
      return trash.restore! if trash
    end
  end
  
  module InstanceMethods
    def store_trash
      unless @acts_as_trashable_disabled
        trash = TrashRecord.new(self)
        trash.save!
      end
    end
    
    # Call this me  thod to temporarily disable the trash feature within a block.
    def disable_trash
      save_val = @acts_as_trashable_disabled
      begin
        @acts_as_trashable_disabled = true
        yield if block_given?
      ensure
        @acts_as_trashable_disabled = save_val
      end
    end
  end
  
end
