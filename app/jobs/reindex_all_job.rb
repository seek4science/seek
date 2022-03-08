# A job that reindexes all searchable classes using solr_reindex

class ReindexAllJob < ApplicationJob

  BATCH_SIZE = 250
  queue_with_priority 3
  queue_as QueueNames::INDEXING

  def perform(type)
    type.constantize.solr_reindex(batch_size: BATCH_SIZE) if type && Seek::Config.solr_enabled
  end

  def timelimit
    2.hours
  end

end
