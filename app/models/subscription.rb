require 'acts_as_authorized'
class Subscription < ActiveRecord::Base
  belongs_to :person, :required_access => false
  belongs_to :subscribable, :required_access => false, :polymorphic => true

  validates_presence_of :person
  validates_presence_of :subscribable

  #these should be ordered fastest to slowest
  FREQUENCIES = ['immediately', 'daily', 'weekly', 'monthly']

  FREQUENCIES.each do |s_type|
    define_method "#{s_type}?" do
      frequency == s_type
    end
  end

  #TODO: add a way for the user to set a frequency for projects they don't subscribe to.
  def generic_frequency
    ProjectSubscription.find_all_by_person_id(person_id).map(&:frequency).fold('weekly') {|slowest, current|  FREQUENCIES.index(current) > FREQUENCIES.index(slowest) ? current : slowest}
  end

  def frequency
   ProjectSubscription.find_by_person_id_and_project_id(person_id, subscribable.project_id).try(:frequency) || generic_frequency
  end
end