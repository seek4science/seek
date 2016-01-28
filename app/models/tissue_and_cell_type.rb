class TissueAndCellType < ActiveRecord::Base

  has_and_belongs_to_many :deprecated_samples

  validates_presence_of :title
  validates_uniqueness_of :title
end