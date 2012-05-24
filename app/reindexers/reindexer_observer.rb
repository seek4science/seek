#Super class for creating observers that handle the reindexing of consequences of changes to secondary data. For exampel when adding an annotation
#should cause the annotated item to be reindexed, or when changing, adding, or removing a compound shoud cause the related data file to be reindexed.
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
    ReindexingJob.add_items_to_queue(concs,10.seconds.from_now)
  end

end