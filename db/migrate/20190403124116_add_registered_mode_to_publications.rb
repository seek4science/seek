class AddRegisteredModeToPublications < ActiveRecord::Migration[4.2]
  def change
    add_column :publications, :registered_mode, :int
  end
end
