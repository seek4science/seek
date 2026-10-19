# A job that reindexes all searchable classes using solr_reindex

class ReindexAllJob < ApplicationJob

  queue_with_priority 3
  queue_as QueueNames::INDEXING

  def perform(type)
    type.constantize.solr_reindex(batch_size: batch_size) if type && Seek::Config.solr_enabled
  end

  def timelimit
    2.hours
  end

  def batch_size
    Seek::Config.reindex_all_batch_size
  end

end
