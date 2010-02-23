class CreateInstitutions < ActiveRecord::Migration
  def self.up
    create_table :institutions, :force => true do |t|
    t.string   :name
    t.text     :address
    t.string   :city
    t.string   :web_page
    t.string   :country
    t.timestamps
  end

  end

  def self.down
    drop_table :institutions
  end
end
