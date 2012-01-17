class Strain < ActiveRecord::Base
  belongs_to :organism
  has_many :genotypes, :dependent => :destroy
  has_one :phenotype, :dependent => :destroy
  has_many :specimens

  named_scope :by_title

  validates_presence_of :title

  named_scope :without_default,:conditions=>{:is_dummy=>false}

  include ActsAsCachedTree
end
