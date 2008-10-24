class Institution < ActiveRecord::Base
  has_many :work_groups, :dependent => :destroy
  
  validates_presence_of :name, :country
end
