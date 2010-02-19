class UpdateAssayDataFilesForVersions < ActiveRecord::Migration
  def self.up
    select_all('SELECT * FROM created_datas').each do |values|
      assay_id=values["assay_id"]
      df_id=values["data_file_id"]
      df=DataFile.find(df_id)

      a=AssayAsset.new(:assay_id=>assay_id,:asset_id=>df.asset.id,:version=>df.version)
      a.save
    end
  end

  def self.down
    select_all('SELECT * FROM created_datas').each do |values|
      assay_id=values["assay_id"]
      df_id=values["data_file_id"]
      df=DataFile.find(df_id)

      a=AssayAsset.find(:first,:conditions=>["assay_id=? and asset_id=?",assay_id,df.asset.id])
      a.destroy unless a.nil?
    end
  end
end
