class AddFirstLetterToTemplates < ActiveRecord::Migration[6.1]
  def change
		add_column :templates, :first_letter, :string, limit: 1
  end
end
