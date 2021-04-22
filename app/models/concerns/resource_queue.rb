module ResourceQueue
  extend ActiveSupport::Concern
  DEFAULT_PRIORITY = 2.freeze

  included do
    belongs_to :item, polymorphic: true
  end

  class_methods do
    def queue_enabled?
      true
    end

    def prioritized
      # including item_type in the order, encourages assets to be processed before users
      #  (since they are much quicker, in the case of auth lookup processing), due to the happy coincidence that User
      #  falls last alphabetically. Its not that important if a new authorized type is added after User in the future.
      order(:priority, :item_type, :id)
    end

    def enqueue(*items, priority: DEFAULT_PRIORITY, queue_job: true)
      return unless queue_enabled?

      entries = items.flatten.map do |item|
        entry = where(item_id: item&.id, item_type: item ? item.class.name : nil).first_or_initialize
        # Only change priority if its a new entry, or lower than existing. (Lower priority is executed first...)
        entry.priority = priority if entry.new_record? || priority < entry.priority
        yield entry if block_given?
        entry.save!
        entry
      end

      job_class.new.queue_job if queue_job

      entries
    end

    def dequeue(num = 1)
      entries = prioritized.limit(num)
      items = entries.map(&:item)
      entries.destroy_all
      items.uniq
    end
  end
end