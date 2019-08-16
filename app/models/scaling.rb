class Scaling < ApplicationRecord
   belongs_to :scale, :class_name => 'Scale'
   belongs_to :scalable, :polymorphic => true
   belongs_to :person


  validates_presence_of :scale_id,:scalable

  validates_uniqueness_of :scale_id, :scope => [ :scalable_type,:scalable_id]
end