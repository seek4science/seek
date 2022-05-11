class DropRepositoryStandards < ActiveRecord::Migration[5.2]
  def change
    drop_table :repository_standards
  end
end
