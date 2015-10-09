class RenameProgrammeActivated < ActiveRecord::Migration

  def up
    rename_column :programmes, :activated, :is_activated
  end

  def down
    rename_column :programmes, :is_activated, :activated
  end

end
