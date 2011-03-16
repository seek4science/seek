class Favourite < ActiveRecord::Base
  belongs_to :user
  belongs_to :resource, :polymorphic => true
  
  validates_presence_of :resource_id, :resource_type

  def self.for_user(user)
    if Seek::Config.events_enabled
      Favourite.find_all_by_user_id(user.id)
    else
      Favourite.find_all_by_user_id(user.id,:conditions=>['resource_type != ?','Event'])
    end
  end
  
end
