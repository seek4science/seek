class Strain < ActiveRecord::Base
  belongs_to :organism
  has_many :genotypes, :dependent => :destroy
  has_one :phenotype, :dependent => :destroy

  named_scope :by_title

  include ActsAsCachedTree
end
