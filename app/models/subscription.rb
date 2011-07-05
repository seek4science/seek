require 'acts_as_authorized'
class Subscription < ActiveRecord::Base
  belongs_to :person
  belongs_to :subscribable, :polymorphic => true

  validates_presence_of :person
  validates_presence_of :subscribable

  FREQUENCIES = ['immediately', 'daily', 'weekly', 'monthly']

  FREQUENCIES.each do |s_type|
    define_method "#{s_type}?" do
      frequency == s_type
    end
  end

  def frequency
    #TODO: What about items with no project? For now looks at person.projects.first, but thats a tremendous hack
    ProjectSubscription.all.detect {|ps| ps.project == (subscribable.project || person.projects.first) and ps.person == person}.frequency
  end
end