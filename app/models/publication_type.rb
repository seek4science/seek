class PublicationType < ActiveRecord::Base
  has_many :publications
  validates_uniqueness_of :key
  validates_presence_of :key
end
