class ChangeUrlsToText < ActiveRecord::Migration[5.2]

  def up
    change_column :events, :url, :text
    change_column :publications, :url, :text
    change_column :institutions, :web_page, :text
    change_column :people, :web_page, :text
    change_column :programmes, :web_page, :text
    change_column :projects, :web_page, :text
    change_column :projects, :wiki_page, :text
  end

  def down
    change_column :events, :url, :string
    change_column :publications, :url, :string
    change_column :institutions, :web_page, :string
    change_column :people, :web_page, :string
    change_column :programmes, :web_page, :string
    change_column :projects, :web_page, :string
    change_column :projects, :wiki_page, :string
  end

end
