class AddTemplateIdToSampleControlledVocab < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_controlled_vocabs, :template_id, :integer
  end
end
