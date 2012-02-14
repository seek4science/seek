class AddSynonymCommentProviderNameProviderIdToStrains < ActiveRecord::Migration
  def self.up
    add_column :strains,:synonym,:string
    add_column :strains,:comment,:text
    add_column :strains,:provider_id,:integer
    add_column :strains,:provider_name,:string
  end

  def self.down
    remove_column :strains,:synonym
    remove_column :strains,:comment
    remove_column :strains,:provider_id
    remove_column :strains,:provider_name
  end
end
