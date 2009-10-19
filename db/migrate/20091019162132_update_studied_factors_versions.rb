class UpdateStudiedFactorsVersions < ActiveRecord::Migration
  def self.up
    select_all("select * from studied_factors").each do |values|
      df_id=values["data_file_id"]
      df=DataFile.find(df_id)
      update "update studied_factors set data_file_version=#{df.version} where id=#{values["id"]}"
    end
  end

  def self.down
  end
end
