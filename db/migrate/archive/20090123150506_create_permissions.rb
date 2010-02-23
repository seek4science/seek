class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      # Contributor with respect to Permissions is the object that is covered by the settings
      # in the permission - that is by "sharing_scope" and "access_type"; 
      #
      # Contributors can be of the following types:
      # - Person: covers individual people (NB! these are NOT Users, but People - this is because users
      #                                     might want to share assets with people, who don't have a User
      #                                     instance registered for them just yet)
      # - Project: covers all members of a project
      # - Institution: covers all members of an institution
      # - WorkGroup: covers all members of a work group (for example: SysMO @ Manchester);
      # - FavouriteGroup: indicates that Policy (to which the current Permission belongs)
      #                   shares an Asset with a user's favourite group; 
      #                   NB! sharing settings for each member of the group in this case
      #                   will be individual and are stored separately within FavouriteGroupMemberships 
      t.column :contributor_type, :string
      t.column :contributor_id,   :integer
      
      t.column :policy_id,        :integer
      
      # for details, please see explanations in the migration
      # file called "create_policies"; this field is needed
      # to *override* policy settings in "access_type"
      # ("sharing_scope" is not applicable, because it's set
      #   in "contributor_type/_id" in permissions)
      t.column :access_type,      :integer, :limit => 1
      
      t.timestamps
    end
  end

  def self.down
    drop_table :permissions
  end
end
