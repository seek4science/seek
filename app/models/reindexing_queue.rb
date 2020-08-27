class ReindexingQueue < ApplicationRecord
  belongs_to :item, polymorphic: true
  validates :item_id, uniqueness: { scope:  [:item_type] }

  def self.enqueue(*items, queue_job: true)
    return unless Seek::Config.solr_enabled

    entries = items.flatten.map do |item|
      entry = where(item_id: item&.id, item_type: item ? item.class.name : nil).first_or_initialize
      entry.save!
      entry
    end

    ReindexingJob.new.queue_job if queue_job

    entries
  end

  def self.dequeue(num)
    entries = limit(num)
    items = entries.map(&:item)
    entries.destroy_all
    items
  end
end
