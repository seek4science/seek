class TissueAndCellType < ActiveRecord::Base
  validates_presence_of :title
  validates_uniqueness_of :title
end