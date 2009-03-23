class Experiment < ActiveRecord::Base


  belongs_to :assay
  belongs_to :experiment_type
  
  belongs_to :person_responible, :class_name => "Person"

  has_and_belongs_to_many :sops  
  
  validates_presence_of :title
  validates_associated :assay
  
  
end
