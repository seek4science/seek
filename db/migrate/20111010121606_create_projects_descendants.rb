class CreateProjectsDescendants < ActiveRecord::Migration
  def self.up
    create_table :project_descendants ,:id=> false do |t|
      t.integer :ancestor_id
      t.integer :descendant_id
    end
  end

  def self.down
    drop_table :project_descendants
  end
end
