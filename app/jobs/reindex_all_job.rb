# A job that reindexes all searchable classes using solr_reindex

class ReindexAllJob < ApplicationJob

  BATCH_SIZE = 250

  def perform
    Seek::Util.searchable_types.each do |type|
      Rails.logger.info "solr_reindex for #{type.name}"
      type.solr_reindex(batch_size: BATCH_SIZE)
    end
  end

end