class AddSopTypeToSops < ActiveRecord::Migration[7.2]
  def change
    add_column :sops, :sop_type, :string
  end
end
