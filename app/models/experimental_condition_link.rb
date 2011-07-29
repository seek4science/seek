class ExperimentalConditionLink < ActiveRecord::Base
  belongs_to :substance, :polymorphic => true
  belongs_to :experimental_condition

  validates_presence_of :experimental_condition
  validates_presence_of :substance
end
