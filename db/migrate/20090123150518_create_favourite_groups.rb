# This table will hold user-defined "favourite" groups.
# This will include "white_list" and "black_list" groups,
# where members have full access / no access, respectively,
# to either of the user's assets (when the user will choose
# to inlcude these groups).

class CreateFavouriteGroups < ActiveRecord::Migration
  def self.up
    create_table :favourite_groups do |t|
      # it only makes sense to have favourite groups
      # belonging to a User, hence foreign key into
      # the table containing the "owner" of the group
      # is not polymorphic 
      t.column :user_id, :integer
      t.column :name,    :string
      t.timestamps
    end
  end

  def self.down
    drop_table :favourite_groups
  end
end
