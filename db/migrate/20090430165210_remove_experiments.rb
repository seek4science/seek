class RemoveExperiments < ActiveRecord::Migration
  def self.up
    drop_table :experiments
  end

  def self.down
    create_table "experiments" do |t|
      t.string   "title"
      t.text     "description"
      t.integer  "experiment_type_id"
      t.integer  "topic_id"
      t.string   "experimentalist"
      t.datetime "begin_date"
      t.integer  "person_responsible_id"
      t.integer  "organism_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
