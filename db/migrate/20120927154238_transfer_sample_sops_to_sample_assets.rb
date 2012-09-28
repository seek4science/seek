class TransferSampleSopsToSampleAssets < ActiveRecord::Migration
  def self.up
    puts "ddddd"
    select_all("select * from sample_sops").each do |item|
      sample_id=ActiveRecord::Base.connection.quote item["sample_id"]
      sop_id=ActiveRecord::Base.connection.quote item["sop_id"]
      sop_version=ActiveRecord::Base.connection.quote item["sop_version"]
      now = ActiveRecord::Base.connection.quote Time.now.to_s(:db)
      execute "INSERT INTO sample_assets(sample_id,asset_id,asset_type,version,created_at,updated_at) VALUES (#{sample_id},#{sop_id},'Sop',#{sop_version},#{now},#{now})"
    end
  end

  def self.down
    execute "DELETE FROM sample_assets where asset_type='Sop'"
  end
end
