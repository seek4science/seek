class AuthLookupUpdateQueue < ApplicationRecord
  DEFAULT_PRIORITY = 2.freeze

  belongs_to :item, polymorphic: true, required: false
  validates :item_id, uniqueness: { scope:  [:item_type] }

  def self.prioritized
    order(:priority, :item_type, :id)
  end

  def self.enqueue(*items, priority: DEFAULT_PRIORITY, queue_job: true)
    return unless Seek::Config.auth_lookup_enabled

    entries = items.flatten.map do |item|
      entry = where(item_id: item&.id, item_type: item ? item.class.name : nil).first_or_initialize
      # Only change priority if its a new entry, or lower than existing. (Lower priority is executed first...)
      entry.priority = priority if entry.new_record? || priority < entry.priority
      entry.save!
      entry
    end

    AuthLookupUpdateJob.new.queue_job if queue_job

    entries
  end

  def self.dequeue(num = Seek::Config.auth_lookup_update_batch_size)
    entries = prioritized.limit(num)
    items = entries.map(&:item)
    entries.destroy_all
    items
  end
end
