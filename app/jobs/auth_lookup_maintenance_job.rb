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
    items_for_queue = [].to_set
    User.where.not(person_id: nil).to_a.push(nil).each do |user|

      # skip if this user is queued up
      next if AuthLookupUpdateQueue.where(item:user).any?

      # will only deal with 1 type per user per run
      found = Seek::Util.authorized_types.find do |type|
        !type.lookup_table_consistent?(user)
      end

      next unless found.present?

      found_types << found
      missing = found.items_missing_from_authlookup(user)
      items_for_queue.merge(missing)
    end

    found_types.each(&:remove_invalid_auth_lookup_entries)
    AuthLookupUpdateQueue.enqueue(items_for_queue.to_a) unless items_for_queue.empty?
  end

end