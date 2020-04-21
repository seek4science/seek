class AssetsLink < ApplicationRecord
  belongs_to :asset, :polymorphic => true
end
