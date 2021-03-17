# Updates the lookup table for a specific user and asset type
class UserAuthLookupUpdateJob < ApplicationJob
  queue_as QueueNames::AUTH_LOOKUP
  queue_with_priority 0

  def perform(user, type)
    type.constantize.includes(policy: :permissions).find_each do |item|
      item.update_lookup_table(user)
    end
  end
end

