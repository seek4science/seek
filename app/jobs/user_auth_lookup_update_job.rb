# Updates the lookup table for a specific user and asset type
class UserAuthLookupUpdateJob < ApplicationJob
  queue_as QueueNames::AUTH_LOOKUP
  queue_with_priority 0
  BATCH_SIZE = 8000

  # needs longer, otherwise the samples can time out
  def timelimit
    30.minutes
  end

  def perform(user, type, offset = 0)
    type.constantize.offset(offset).limit(BATCH_SIZE).includes(policy: :permissions).each do |item|
      item.update_lookup_table(user)
    end

    offset += BATCH_SIZE

    self.class.perform_later(user, type, offset) if offset < type.constantize.count
  end
end

