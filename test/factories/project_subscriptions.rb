# ProjectSubscription
Factory.define(:project_subscription) do |f|
  f.association :person
  f.association :project
end

# Subscription
Factory.define(:subscription) do |f|
  f.association :person
  f.association :subscribable
end

# NotifieeInfo
Factory.define(:notifiee_info) do |f|
  f.association :notifiee, factory: :person
end
