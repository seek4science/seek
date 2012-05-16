class Phenotype < ActiveRecord::Base
  belongs_to :strain
  validates_presence_of :description,:message=>"of phenotype can't be blank"
end
