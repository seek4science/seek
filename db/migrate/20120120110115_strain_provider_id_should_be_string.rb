class StrainProviderIdShouldBeString < ActiveRecord::Migration
  def self.up
    change_column :strains,:provider_id,:string
  end

  def self.down
    change_column :strains,:provider_id,:integer
  end
end
