class Compound < ActiveRecord::Base
  has_many :studied_factors, :as => :substance
  has_many :synonyms, :as => :substance

  validates_presence_of :name
  validates_uniqueness_of :name

end
