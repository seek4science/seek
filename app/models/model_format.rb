class ModelFormat < ActiveRecord::Base
  validates_uniqueness_of :title
  validates_presence_of :title

  has_many :models
end
