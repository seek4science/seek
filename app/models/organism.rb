class Organism < ActiveRecord::Base

  has_many :sops
  has_many :models

  validates_presence_of :title

end
