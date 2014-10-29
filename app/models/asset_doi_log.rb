class AssetDoiLog < ActiveRecord::Base
  attr_accessible :action, :asset_id, :asset_type, :asset_version, :comment

  belongs_to :asset, :polymorphic => true #, :required_access => false
  belongs_to :user #, :required_access => false

  MINT = 1
  DELETE = 2
  UNPUBLISH = 3

  def self.is_doi_minted_for?(asset_type, asset_id)
    !AssetDoiLog.where(asset_type: asset_type, asset_id: asset_id, action: AssetDoiLog::MINT).empty?
  end
end
