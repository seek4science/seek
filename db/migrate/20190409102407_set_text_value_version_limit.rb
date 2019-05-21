class SetTextValueVersionLimit < ActiveRecord::Migration[5.2]

  def up
    change_column :text_values, :text,  :text, limit: 16777215
  end

  def down
    change_column :text_values, :text,  :text, limit: 4294967295
  end

end
