class ChangeExperimentalistsToText < ActiveRecord::Migration
  def up
    change_column :studies, :experimentalists, :text
  end

  def down
    change_column :studies, :experimentalists, :string
  end

end
