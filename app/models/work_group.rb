class WorkGroup < ActiveRecord::Base
  belongs_to :institution
  belongs_to :project
end
