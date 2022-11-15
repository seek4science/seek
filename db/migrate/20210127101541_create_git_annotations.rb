class CreateGitAnnotations < ActiveRecord::Migration[5.2]
  def change
    create_table :git_annotations do |t|
      t.references :git_version
      t.references :contributor
      t.string :path
      t.string :key
      t.text :value
      t.timestamps
    end
  end
end
