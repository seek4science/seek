class Investigation < ActiveRecord::Base

  has_many :studies
  belongs_to :project
end
