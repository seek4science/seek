class CreateIsaTags < ActiveRecord::Migration[5.2]
  def change
    create_table :isa_tags do |t|
      t.string :title
    end
    add_index :isa_tags, :title, name: 'index_isa_tags_title'
  end
end
