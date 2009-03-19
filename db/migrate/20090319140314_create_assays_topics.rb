class CreateAssaysTopics < ActiveRecord::Migration
  
  def self.up
    create_table :assays_topics,:id=>false do |t|
      t.integer :assay_id
      t.integer :topic_id
    end
  end

  def self.down
    drop_table :assays_topics
  end

end
