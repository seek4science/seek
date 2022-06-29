class AddOtherCreatorsToTemplates < ActiveRecord::Migration[6.1]
  def change
		add_column :templates, :other_creators, :text
  end
end
