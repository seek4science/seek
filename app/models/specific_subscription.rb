require 'acts_as_authorized'
class SpecificSubscription < ActiveRecord::Base
  belongs_to :person
  belongs_to :project
  belongs_to :subscribable, :polymorphic => true

  validates_presence_of :person
  validates_presence_of :subscribable
  #validates_presence_of :project project might be nil for some resource

  [:daily, :monthly, :weekly, :immediate].each do |sym|
    define_method "#{sym}?" do
      subscription_type == Subscription.const_get(sym.to_s.upcase)
    end
  end

end