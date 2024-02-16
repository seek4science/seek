class AuthLookupDeleteJob < ApplicationJob
  BATCH_SIZE = 1000
  queue_as QueueNames::AUTH_LOOKUP
  queue_with_priority 2

  def perform(item_class, item_id)
    if item_class == 'User'
      Seek::Util.authorized_types.each do |type|
        type.lookup_class.where(user: item_id).in_batches(of: BATCH_SIZE).delete_all
      end
    else
      item_class.constantize.lookup_class.where(asset_id: item_id).in_batches(of: 100000, order: :desc) { |r| r.delete_all }
    end
  end
end
