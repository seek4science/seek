class Compound < ActiveRecord::Base
  has_many :studied_factors, :as => :compound
  validates_presence_of :name
  validates_uniqueness_of :name
end
