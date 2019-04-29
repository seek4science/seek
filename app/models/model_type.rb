class ModelType < ApplicationRecord

  validates_uniqueness_of :title
  validates_presence_of :title

  has_many :models
end
