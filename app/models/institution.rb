class Institution < ActiveRecord::Base
  has_many :work_groups, :dependent => :destroy
end
