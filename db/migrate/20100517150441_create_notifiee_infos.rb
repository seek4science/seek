class CreateNotifieeInfos < ActiveRecord::Migration
  def self.up
    create_table :notifiee_infos do |t|
      t.column :notifiee_id,:integer
      t.column :notifiee_type,:string
      t.column :unique_key,:string
      t.column :receive_notifications,:boolean,:default=>true
            
      t.timestamps
    end
  end

  def self.down
    drop_table :notifiee_infos
  end
end
