class RemoveTemplateIdFromSampleControlledVocab < ActiveRecord::Migration[7.2]
  def change
    remove_column :sample_controlled_vocabs, :template_id, :integer
  end
end
