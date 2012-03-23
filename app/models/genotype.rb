class Genotype < ActiveRecord::Base
  belongs_to :strain
  belongs_to :gene
  belongs_to :modification
  validates_presence_of :gene
end
