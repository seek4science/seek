class Favourite < ActiveRecord::Base
  belongs_to :user
  belongs_to :resource, :polymorphic => true
  
  validates_presence_of :resource_id, :resource_type
end
