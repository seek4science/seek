class UpdateAssaySopForVersions < ActiveRecord::Migration
  def self.up
    select_all('SELECT * FROM assays_sops').each do |values|
      assay_id=values["assay_id"]
      sop_id=values["sop_id"]
      sop=Sop.find(sop_id)
      
      a=AssayAsset.new(:assay_id=>assay_id,:asset_id=>sop.asset.id,:version=>sop.version)
      a.save
    end
  end

  def self.down
    select_all('SELECT * FROM assays_sops').each do |values|
      assay_id=values["assay_id"]
      sop_id=values["sop_id"]
      sop=Sop.find(sop_id)
      a=AssayAsset.find(:first,:conditions=>["assay_id=? and asset_id=?",assay_id,sop.asset.id])
      a.destroy unless a.nil?
    end
  end
end
