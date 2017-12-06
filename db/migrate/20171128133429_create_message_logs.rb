class CreateMessageLogs < ActiveRecord::Migration
  def change
    create_table :message_logs do |t|
      t.timestamps true
      t.integer :message_type
      t.text :details
      t.references :resource, polymorphic: true,index:true
      t.references :sender, references: :people, index:true
    end
  end
end
