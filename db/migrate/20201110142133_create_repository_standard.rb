class CreateRepositoryStandard < ActiveRecord::Migration[5.2]
  def change
    create_table :repository_standards do |t|
      t.string :title
      t.string :url
      t.string :group_tag
      t.string :repo_type # study or assay characteristics
      t.text :description
    end
    add_index :repository_standards, [:title, :group_tag], name: 'index_repository_standards_title_group_tag'
  end
end
