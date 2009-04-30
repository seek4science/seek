class RemoveExperimentTypes < ActiveRecord::Migration
  def self.up
    drop_table :experiment_types
  end

  def self.down
    create_table "experiment_types" do |t|
      t.string   "title"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
