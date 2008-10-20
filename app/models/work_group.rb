class WorkGroup < ActiveRecord::Base
  belongs_to :institution
  belongs_to :project
  has_and_belongs_to_many :people
end
