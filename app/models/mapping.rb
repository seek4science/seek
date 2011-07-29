class Mapping < ActiveRecord::Base
  has_many :mapping_links

  validates_presence_of :sabiork_id
  acts_as_solr(:field => [{:sabiork_id => :integer}, :chebi_id, :kegg_id]) if Seek::Config.solr_enabled
end
