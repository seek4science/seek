class AddPublishStateColumn < ActiveRecord::Migration
  def self.up
    add_column :investigations, :publish_state, :integer
    add_column :studies, :publish_state, :integer
    add_column :assays, :publish_state, :integer
    add_column :data_files, :publish_state, :integer
    add_column :models, :publish_state, :integer
    add_column :sops, :publish_state, :integer
    add_column :presentations, :publish_state, :integer
    add_column :events, :publish_state, :integer
    add_column :strains, :publish_state, :integer
    add_column :specimens, :publish_state, :integer
    add_column :samples, :publish_state, :integer

    add_column :data_file_versions, :publish_state, :integer
    add_column :model_versions, :publish_state, :integer
    add_column :sop_versions, :publish_state, :integer
    add_column :presentation_versions, :publish_state, :integer
  end

  def self.down
    remove_column :investigations, :publish_state
    remove_column :studies, :publish_state
    remove_column :assays, :publish_state
    remove_column :data_files, :publish_state
    remove_column :models, :publish_state
    remove_column :sops, :publish_state
    remove_column :presentations, :publish_state
    remove_column :events, :publish_state
    remove_column :strains, :publish_state
    remove_column :specimens, :publish_state
    remove_column :samples, :publish_state

    remove_column :data_file_versions, :publish_state
    remove_column :model_versions, :publish_state
    remove_column :sop_versions, :publish_state
    remove_column :presentation_versions, :publish_state
  end
end
