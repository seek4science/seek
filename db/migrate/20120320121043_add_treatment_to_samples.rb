class AddTreatmentToSamples < ActiveRecord::Migration
  def self.up
    add_column :samples,:treatment,:string
  end

  def self.down
    remove_column :samples,:treatment
  end
end
