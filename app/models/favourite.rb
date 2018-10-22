class Favourite < ApplicationRecord
  belongs_to :user
  belongs_to :resource, :polymorphic => true
  
  validates_presence_of :resource_id, :resource_type
  validates :user_id, :uniqueness => { :scope =>  [:resource_type, :resource_id] }

  after_destroy :destroy_saved_search

  def self.for_user(user)
    if Seek::Config.events_enabled
      Favourite.where(:user_id => user.id)
    else
      Favourite.where(['user_id = ? AND resource_type != ?',user.id,'Event'])
    end
  end

  private

  def destroy_saved_search
    if resource_type_was == 'SavedSearch'
      SavedSearch.find(resource_id_was).destroy
    end
  end
end
