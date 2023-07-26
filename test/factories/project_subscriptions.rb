FactoryBot.define do
  # ProjectSubscription
  factory(:project_subscription) do
    association :person
    association :project
  end
  
  # Subscription
  factory(:subscription) do
    association :person
    association :subscribable
  end
  
  # NotifieeInfo
  factory(:notifiee_info) do
    association :notifiee, factory: :person
  end
end
