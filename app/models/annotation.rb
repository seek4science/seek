# app/models/annotation.rb
#
# This extends the Annotation model defined in the Annotations plugin.

require_dependency File.join(Rails.root, 'vendor', 'plugins', 'annotations', 'lib', 'app', 'models', 'annotation')

class Annotation < ActiveRecord::Base

  before_save :reindex if Seek::Config.solr_enabled


  private

  def reindex
    if annotatable.respond_to? :reindexing_consequences
      annotatable.reindexing_consequences.each do |consequence|
        consequence.solr_save if consequence.respond_to? :solr_save
      end
    end
  end

end
