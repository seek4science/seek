class Organism < ActiveRecord::Base

  has_many :sops

  validates_presence_of :title

end
