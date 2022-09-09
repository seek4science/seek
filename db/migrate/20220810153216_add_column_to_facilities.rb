class AddColumnToFacilities < ActiveRecord::Migration[6.1]
  def up
    unless column_exists? :facilities, :address
      add_column :facilities, :address, :text
      add_column :facilities, :city, :string
      add_column :facilities, :web_page, :text
      add_column :facilities, :country, :string
    end
  end
  def down
    if column_exists? :facilities, :address
      remove_column :facilities, :address, :text
      remove_column :facilities, :city, :string
      remove_column :facilities, :web_page, :text
      remove_column :facilities, :country, :string
    end
  end
end
