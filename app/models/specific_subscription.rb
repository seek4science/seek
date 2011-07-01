require 'acts_as_authorized'
class SpecificSubscription < ActiveRecord::Base
  belongs_to :person
  belongs_to :project
  belongs_to :subscribable, :polymorphic => true

  validates_presence_of :person
  validates_presence_of :subscribable
  #validates_presence_of :project project might be nil for some resource


end