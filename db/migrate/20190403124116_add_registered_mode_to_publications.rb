class AddRegisteredModeToPublications < ActiveRecord::Migration
  def change
    add_column :publications, :registered_mode, :int
  end
end
