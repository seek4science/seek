class ChangeStudiedFactorsLinkToStudyNotDatafile < ActiveRecord::Migration
  def self.up
    rename_column(:studied_factors, :data_file_id, :study_id)
  end

  def self.down
    rename_column(:studied_factors, :study_id,:data_file_id)
  end
end
