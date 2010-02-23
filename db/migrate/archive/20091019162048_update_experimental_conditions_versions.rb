class UpdateExperimentalConditionsVersions < ActiveRecord::Migration
  def self.up
    select_all("select * from experimental_conditions").each do |values|
      sop_id=values["sop_id"]
      sop=Sop.find(sop_id)
      update "update experimental_conditions set sop_version=#{sop.version} where id=#{values["id"]}"
    end
  end

  def self.down
  end
end
