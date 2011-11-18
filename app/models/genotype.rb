class Genotype < ActiveRecord::Base
  belongs_to :strain
  belongs_to :gene
  belongs_to :modification
end
