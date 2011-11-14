class Strain < ActiveRecord::Base
  belongs_to :organism
  has_many :genotypes
  has_one :phenotype

  named_scope :by_title

  include ActsAsCachedTree
end
