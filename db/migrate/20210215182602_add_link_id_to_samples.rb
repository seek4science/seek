class AddLinkIdToSamples < ActiveRecord::Migration[5.2]
  def change
    add_column :samples, :link_id, :string
  end
end
