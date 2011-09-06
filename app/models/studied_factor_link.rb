class StudiedFactorLink < ActiveRecord::Base
  belongs_to :substance, :polymorphic => true
  belongs_to :studied_factor

  validates_presence_of :studied_factor
  validates_presence_of :substance, :message => "can't be blank"
end
