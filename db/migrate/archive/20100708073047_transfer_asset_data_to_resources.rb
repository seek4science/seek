require 'save_without_timestamping'

#Needed because Asset model may not exist any more
class Asset < ActiveRecord::Base  
  belongs_to :resource, :polymorphic => true
end

class TransferAssetDataToResources < ActiveRecord::Migration
  def self.up
    count = 0
    Asset.all.each do |asset|
      resource = asset.resource
      resource.policy_id = asset.policy_id
      resource.project_id = asset.project_id
      if resource.save_without_timestamping
        count += 1
      end
      
      if ["DataFile","Model","Sop"].include?(resource.class.name)
        resource.versions.each do |version|
          version.policy_id = asset.policy_id
          version.project_id = asset.project_id
          version.save_without_timestamping
        end
      end
    end
    puts "#{count}/#{Asset.count} asset resources updated."
  end

  def self.down
    count = 0
    Asset.all.each do |asset|
      resource = asset.resource
      resource.policy_id = nil
      resource.project_id = nil
      if ["DataFile","Model","Sop"].include?(resource.class.name)
        resource.versions.each do |version|
          version.policy_id = nil
          version.project_id = nil
          version.save_without_timestamping
        end
      end
      
      if resource.save_without_timestamping
        count += 1
      end
    end
    puts "#{count}/#{Asset.count} asset resources reverted."
  end
end
