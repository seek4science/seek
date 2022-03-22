#Super class for creating observers that handle the reindexing of consequences of changes to secondary data.
#
#To create a reindexer you should subclass and implement the consequences(item) method to return an array of items to be indexed, define the model to be observed user 'observe'
# and add the observer to the list of config.active_record.observers in config/environment.rb

class ReindexerObserver < ActiveRecord::Observer

  def after_save item
    reindex(item) if Seek::Config.solr_enabled
  end

  def after_destroy item
    reindex(item) if Seek::Config.solr_enabled
  end

  def reindex item
    concs = Array(consequences(item))
    ReindexingQueue.enqueue(concs)
  end

end