class CreateAvatars < ActiveRecord::Migration
  def self.up
    create_table :avatars do |t|
      t.column :owner_type, :string
      t.column :owner_id, :integer
      t.column :original_filename, :string
      t.timestamps
    end
    
    # now need to include foreign keys into the tables that would require avatars
    add_column :people, :avatar_id, :integer
    add_column :projects, :avatar_id, :integer
    add_column :institutions, :avatar_id, :integer
  end

  def self.down
    drop_table :avatars
    
    # revert other affected tables
    remove_column :people, :avatar_id
    remove_column :projects, :avatar_id
    remove_column :institutions, :avatar_id
  end
end
