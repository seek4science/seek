class Phenotype < ActiveRecord::Base
  belongs_to :strain
  belongs_to :deprecated_specimen
  validates_presence_of :description,:message=>"of phenotype can't be blank"
end
