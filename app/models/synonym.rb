class Synonym < ApplicationRecord

  belongs_to :substance, :polymorphic => true
  validates_presence_of :name, :substance

  alias_attribute :title,:name

end

