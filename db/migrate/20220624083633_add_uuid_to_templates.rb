class AddUuidToTemplates < ActiveRecord::Migration[6.1]
  def change
		add_column :templates, :uuid, :string
  end
end
