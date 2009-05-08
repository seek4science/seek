class CreateFactorTypes < ActiveRecord::Migration
  def self.up
    create_table :factor_types do |t|
      t.string :title

      t.timestamps
    end
  end

  def self.down
    drop_table :factor_types
  end
end
