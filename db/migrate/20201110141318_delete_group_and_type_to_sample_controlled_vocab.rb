class DeleteGroupAndTypeToSampleControlledVocab < ActiveRecord::Migration[5.2]
  def change
    remove_column :sample_controlled_vocabs, :group, :string
    remove_column :sample_controlled_vocabs, :item_type, :string
  end
end
