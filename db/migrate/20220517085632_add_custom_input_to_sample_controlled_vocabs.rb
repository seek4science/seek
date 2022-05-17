class AddCustomInputToSampleControlledVocabs < ActiveRecord::Migration[6.1]
  def change
		add_column :sample_controlled_vocabs, :custom_input, :boolean, default: false
  end
end
