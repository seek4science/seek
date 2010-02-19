class ChangeCultureLinkToSop < ActiveRecord::Migration
  def self.up
    rename_column :cultures,:study_id,:sop_id
  end

  def self.down
    rename_column :cultures,:sop_id,:study_id
  end
end
