class Compound < ApplicationRecord
  include Seek::Rdf::RdfGeneration
  has_many :synonyms, :as => :substance
  has_many :mapping_links, :as => :substance
  has_many :mappings, :through=>:mapping_links


  alias_attribute :title,:name

  validates_presence_of :name
  validates_uniqueness_of :name

  def chebi_ids
    mappings.collect{|m| m.chebi_id}.compact
  end

  def sabiork_ids
    mappings.collect{|m| m.sabiork_id}.compact
  end

end
