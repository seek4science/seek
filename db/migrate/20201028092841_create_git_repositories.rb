class CreateGitRepositories < ActiveRecord::Migration[5.2]
  def change
    create_table :git_repositories do |t|
      t.references :resource, polymorphic: true
      t.string :uuid
      t.text :remote
    end
  end
end
