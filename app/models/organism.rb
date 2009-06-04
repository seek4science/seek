class Organism < ActiveRecord::Base

  has_many :assays
  has_many :models

  validates_presence_of :title

end
