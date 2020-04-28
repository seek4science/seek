class AssetsLink < ApplicationRecord
  belongs_to :asset, :polymorphic => true
    validates :url, format: URI::regexp(%w[http https])
end
