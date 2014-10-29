class AssetDoiLog < ActiveRecord::Base
  attr_accessible :action, :asset_id, :asset_type, :asset_version, :comment

  belongs_to :asset, :polymorphic => true #, :required_access => false
  belongs_to :user #, :required_access => false

  MINT = 1
  DELETE = 2
  UNPUBLISH = 3
end
