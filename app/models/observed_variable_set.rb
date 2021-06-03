class ObservedVariableSet < ApplicationRecord
    has_many :observed_variables
    belongs_to :contributor, class_name: 'Person'
end
