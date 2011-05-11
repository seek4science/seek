class Compound < ActiveRecord::Base
  has_many :studied_factors, :as => :compound
  has_many :synonyms, :as => :reference

  validates_presence_of :name
  validates_uniqueness_of :name
end
