class ReindexingQueue < ApplicationRecord
  belongs_to :item, :polymorphic => true
end
