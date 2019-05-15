class Gene < ApplicationRecord
  has_many :genotypes
  validates_presence_of :title,:message=>"of gene can't be blank"
end
