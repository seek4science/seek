module ResourceQueue
  extend ActiveSupport::Concern

  included do
    belongs_to :item, polymorphic: true
    validates :item_id, uniqueness: { scope:  [:item_type] }
  end

  class_methods do
    def enqueue(*items, queue_job: true)
      return unless Seek::Config.solr_enabled

      entries = items.flatten.map do |item|
        entry = where(item_id: item&.id, item_type: item ? item.class.name : nil).first_or_initialize
        entry.save!
        entry
      end

      job_class.new.queue_job if queue_job

      entries
    end

    def dequeue(num)
      entries = limit(num)
      items = entries.map(&:item)
      entries.destroy_all
      items
    end
  end
end