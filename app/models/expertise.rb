class Expertise < ActiveRecord::Base
  
  acts_as_solr(:fields => [ :name ]) if SOLR_ENABLED
  
  has_and_belongs_to_many :people
end
