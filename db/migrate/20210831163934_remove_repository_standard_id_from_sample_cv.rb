class RemoveRepositoryStandardIdFromSampleCv< ActiveRecord::Migration[5.2]
  def change
    remove_column :sample_controlled_vocabs, :repository_standard_id
  end
end
