class AuthLookupDeleteJob < ApplicationJob
  # optimum batch size is different according the queries due to different indexes and ordering
  USER_BATCH_SIZE=500
  ASSET_BATCH_SIZE=10000

  queue_as QueueNames::AUTH_LOOKUP
  queue_with_priority 2

  def perform(item_class, item_id)
    if item_class == 'User'
      Seek::Util.authorized_types.each do |type|
        type.lookup_class.where(user: item_id).in_batches(of: USER_BATCH_SIZE).delete_all
      end
    else
      item_class.constantize.lookup_class.where(asset_id: item_id).in_batches(of: ASSET_BATCH_SIZE, order: :desc) { |r| r.delete_all }
    end
  end
end
