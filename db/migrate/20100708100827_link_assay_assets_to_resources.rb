require 'save_without_timestamping'

#In case Asset is gone
class Asset < ActiveRecord::Base 
  belongs_to :resource, :polymorphic => true
end

#Needed so we can use model logic
class AssayAsset < ActiveRecord::Base
  belongs_to :asset
end

class LinkAssayAssetsToResources < ActiveRecord::Migration
  def self.up
    count = 0
    total = AssayAsset.count
    AssayAsset.all.each do |assay_asset|
      resource = assay_asset.asset.resource.find_version(assay_asset.version)
      assay_asset.asset_id = resource.id
      assay_asset.asset_type = resource.class.name
      if assay_asset.save_without_timestamping
        count += 1
      end
    end
    
    puts "#{count}/#{total} AssayAssets updated successfully."
  end

  def self.down
    #There's not really a way to undo this!
  end
end
