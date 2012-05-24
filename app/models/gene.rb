class Gene < ActiveRecord::Base
  validates_presence_of :title,:message=>"of gene can't be blank"
end
