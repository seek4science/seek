class OrganismSpecimen < ActiveRecord::Base

  belongs_to :specimen
  belongs_to :organism
  belongs_to :culture_growth_type
  belongs_to :strain

  validates_presence_of :specimen
  validates_presence_of :organism

end