class AddGroupAndTypeToSampleControlledVocab < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_controlled_vocabs, :group, :string
    add_column :sample_controlled_vocabs, :item_type, :string
  end
end
