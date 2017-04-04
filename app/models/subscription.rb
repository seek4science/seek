
class Subscription < ActiveRecord::Base
  belongs_to :person #, :required_access => false
  belongs_to :subscribable, :polymorphic => true #,:required_access => false
  belongs_to :project_subscription

  validates_presence_of :person
  validates_presence_of :subscribable

  scope :for_subscribable, -> (item) { where('subscribable_id=? and subscribable_type=?', item.id, item.class.name) }

  #these should be ordered fastest to slowest
  FREQUENCIES = ['immediately', 'daily', 'weekly', 'monthly']

  FREQUENCIES.each do |s_type|
    define_method "#{s_type}?" do
      frequency == s_type
    end
  end

  #uses the frequency based upon the related project_subscription, however,
  #if this item was subscribed to individually (i.e with no project or frequency), then it makes an intelligent guess based on other project subscriptions
  #as a last resort, the frequency will be weekly
  def frequency
    project_subscription.try(:frequency) || fastest_related_project_subscription_frequency || slowest_fallback_related_frequency || "weekly"
  end

  private

  #picks out the most frequent frequency that this person has for the projects related to this subscribable
  def fastest_related_project_subscription_frequency
    proj_subs = subscribable.projects.collect{|p|ProjectSubscription.find_by_person_id_and_project_id person_id, p.try(:id) }.compact
    proj_subs.collect(&:frequency).inject {|fastest, current| FREQUENCIES.index(current) < FREQUENCIES.index(fastest) ? current : fastest}
  end

  #TODO: add a way for the user to set a frequency for projects they don't subscribe to.
  #final fall back for when the person of the subscribable is not subscribed to any related projects - just picks their slowest frequency subscription of all project subscriptions
  def slowest_fallback_related_frequency
    ProjectSubscription.where(person_id: person_id).map(&:frequency).inject{|slowest, current|  FREQUENCIES.index(current) > FREQUENCIES.index(slowest) ? current : slowest}
  end
end
