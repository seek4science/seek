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
    ProjectSubscription.find_all_by_person_id(person_id).map(&:frequency).inject('weekly') {|slowest, current|  FREQUENCIES.index(current) > FREQUENCIES.index(slowest) ? current : slowest}
  end

  def frequency
    proj_subs = subscribable.projects.collect {|p|ProjectSubscription.find_by_person_id_and_project_id person_id, p.try(:id) }.compact
    proj_subs.collect(&:frequency).inject {|fastest, current| FREQUENCIES.index(current) < FREQUENCIES.index(fastest) ? current : fastest} || generic_frequency
  end
end