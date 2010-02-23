class CreatePolicies < ActiveRecord::Migration
  def self.up
    create_table :policies do |t|
      # generally, Contributor for policy is the uploader
      # of an Asset; however, it's possible that someone
      # else would define a policy for certain types of
      # Assets - hence such configuration option is provided
      t.column :contributor_type, :string
      t.column :contributor_id,   :integer
      
      t.column :name,             :string
      
      # "sharing_scope" defines who does this policy affect;
      # "access_type" states which access rights will members
      #   of "sharing_scope" have;
      #
      # values stored here will be short integer values
      # (occupying 1 byte each) indicating codes for each
      # mode - these will be defined within the relevant models
      t.column :sharing_scope,    :integer, :limit => 1
      t.column :access_type,      :integer, :limit => 1
      
      # flags that will be set during creation / update
      # of a policy and would speed up the authorization
      # process by limiting DB accesses, where relevant
      t.column :use_custom_sharing, :boolean
      t.column :use_whitelist,     :boolean
      t.column :use_blacklist,     :boolean

      t.timestamps
    end
  end

  def self.down
    drop_table :policies
  end
end
