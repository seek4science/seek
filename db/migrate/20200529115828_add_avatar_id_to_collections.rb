class AddAvatarIdToCollections < ActiveRecord::Migration[5.2]
  def change
    add_reference :collections, :avatar, index: true
  end
end
