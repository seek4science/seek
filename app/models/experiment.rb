class Experiment < ActiveRecord::Base


  has_and_belongs_to_many :assays
  has_and_belongs_to_many :sops
  belongs_to :project
  
  validates_presence_of :title
  
  
end
