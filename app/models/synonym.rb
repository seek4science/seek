class Synonym < ActiveRecord::Base
  belongs_to :substance, :polymorphic => true
  validates_presence_of :name
end
