class UserAuthLookupUpdateJob < ApplicationJob
  queue_as QueueNames::AUTH_LOOKUP
  queue_with_priority 0

  BATCH_SIZE = 500

  def perform(user, type, offset = 0)
    type.offset(offset).limit(BATCH_SIZE).includes(policy: :permissions).find_each do |item|
      item.update_lookup_table(user)
    end

    offset += BATCH_SIZE

    self.class.perform_later(user, type, offset) if offset < type.count
  end
end
