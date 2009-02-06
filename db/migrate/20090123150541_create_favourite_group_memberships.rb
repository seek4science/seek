class CreateFavouriteGroupMemberships < ActiveRecord::Migration
  def self.up
    create_table :favourite_group_memberships do |t|
      # users will want to share with Persons, not with Users;
      # this is to allow sharing with Persons, who don't have a
      # registered user account on SysMO just yet
      t.column :person_id,          :integer
      t.column :favourite_group_id, :integer
      
      # see "create_policies" migration file for explanations about this field
      t.column :access_type,        :integer, :limit => 1
      
      t.timestamps
    end
  end

  def self.down
    drop_table :favourite_group_memberships
  end
end
