class Strain < ActiveRecord::Base
  belongs_to :organism
  has_many :genotypes, :dependent => :destroy
  has_one :phenotype, :dependent => :destroy
  has_many :specimens

  named_scope :by_title

  validates_presence_of :title, :organism

  include ActsAsCachedTree
end
