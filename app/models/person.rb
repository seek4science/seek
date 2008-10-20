class Person < ActiveRecord::Base
  has_one :profile
  has_and_belongs_to_many :work_groups
end
