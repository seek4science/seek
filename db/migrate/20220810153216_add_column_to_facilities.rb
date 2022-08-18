class AddColumnToFacilities < ActiveRecord::Migration[6.1]
  def change
    add_column :facilities, :address, :text
    add_column :facilities, :city, :string
    add_column :facilities, :web_page, :text
    add_column :facilities, :country, :string
  end
end
