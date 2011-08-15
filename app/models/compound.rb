class Compound < ActiveRecord::Base
  has_many :studied_factor_links, :as => :substance
  has_many :experimental_condition_links,:as => :substance
  has_many :synonyms, :as => :substance
  has_many :mapping_links, :as => :substance

  validates_presence_of :name
  validates_uniqueness_of :name

  acts_as_solr(:fields => [:name], :include => [{:synonyms => {:fields => [:name]}}]) if Seek::Config.solr_enabled

end
