class AuthLookupMaintenanceJob < ApplicationJob
  RUN_PERIOD = 8.hours.freeze

  queue_as QueueNames::AUTH_LOOKUP
  queue_with_priority  3

  def perform
    check_authlookup_consistency
  end

  # checks lookup_table_consistent? on each type for each user, and if not triggers a job to repopulate for that user
  def check_authlookup_consistency
    found_types = [].to_set

    Seek::Util.authorized_types.each do |type|
      #skip if there are any items of this type queued
      next if AuthLookupUpdateQueue.where(item_type: type.name).any?

      items_for_queue = [].to_set

      User.where.not(person_id: nil).to_a.push(nil).each do |user|

        # skip if this user or person is queued up
        next if user && AuthLookupUpdateQueue.where(item: user).or(AuthLookupUpdateQueue.where(item: user.person)).any?

        next if type.lookup_table_consistent?(user)

        items_for_queue.merge(type.items_missing_from_authlookup(user))
        found_types << type
      end
      AuthLookupUpdateQueue.enqueue(items_for_queue.to_a) unless items_for_queue.empty?
    end

    found_types.each(&:remove_invalid_auth_lookup_entries)
  end



end