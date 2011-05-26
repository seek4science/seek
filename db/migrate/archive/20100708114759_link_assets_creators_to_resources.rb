require 'save_without_timestamping'

#In case Asset is gone
class Asset < ActiveRecord::Base  
  belongs_to :resource, :polymorphic => true
end

#Needed so we can use model logic
class AssetsCreator < ActiveRecord::Base
  belongs_to :asset
end

class LinkAssetsCreatorsToResources < ActiveRecord::Migration
  def self.up
    count = 0
    total = AssetsCreator.count
    AssetsCreator.all.each do |asset_creator|
      resource = asset_creator.asset.resource
      asset_creator.asset_id = resource.id
      asset_creator.asset_type = resource.class.name
      if asset_creator.save
        count += 1
      end
    end
    
    puts "#{count}/#{total} AssetCreators updated successfully."
  end

  def self.down
    #There's not really a way to undo this!
  end
end
