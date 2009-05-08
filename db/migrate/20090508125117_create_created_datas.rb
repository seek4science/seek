class CreateCreatedDatas < ActiveRecord::Migration
  def self.up
    create_table :created_datas do |t|
      t.string :status
      t.integer :person_id
      t.integer :data_file_id
      t.integer :assay_id

      t.timestamps
    end
  end

  def self.down
    drop_table :created_datas
  end
end
