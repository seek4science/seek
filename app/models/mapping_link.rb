class MappingLink < ActiveRecord::Base
  belongs_to :substance, :polymorphic => true
  belongs_to :mapping

  validates_presence_of :substance, :mapping
end
