class Discipline < ApplicationRecord
  has_and_belongs_to_many :people
end
