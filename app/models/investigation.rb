class Investigation < ActiveRecord::Base
  
  belongs_to :project
  has_many :studies

  validates_presence_of :title
  validates_presence_of :project
  validates_uniqueness_of :title
  
end
