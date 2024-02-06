class ChangeControlledVocabRootTermUri < ActiveRecord::Migration[6.1]
  def change
    rename_column :sample_controlled_vocabs, :ols_root_term_uri, :ols_root_term_uris
  end
end
