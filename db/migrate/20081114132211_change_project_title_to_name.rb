class ChangeProjectTitleToName < ActiveRecord::Migration
  def self.up
      rename_column(:projects, :title,:name)
  end

  def self.down
      rename_column(:projects, :name,:title)
  end
end
