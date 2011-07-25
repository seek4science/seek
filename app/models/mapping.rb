class Mapping < ActiveRecord::Base
  has_many :mapping_links

  validates_presence_of :sabiork_id
end
