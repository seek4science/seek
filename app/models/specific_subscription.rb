class SpecificSubscription < ActiveRecord::Base
  belongs_to :person
  belongs_to :project
  belongs_to :subscribable, :polymorphic => true

  validates_presence_of :person
  validates_presence_of :subscribable



end