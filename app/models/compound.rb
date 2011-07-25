class Compound < ActiveRecord::Base
  has_many :studied_factors, :as => :substance
  has_many :experimental_conditions,:as => :substance
  has_many :synonyms, :as => :substance
  has_many :mapping_links, :as => :substance

  validates_presence_of :name
  validates_uniqueness_of :name

end
