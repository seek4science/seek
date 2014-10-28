class AssetDoiLog < ActiveRecord::Base
  attr_accessible :action, :asset_id, :asset_type, :asset_version, :comment
end
