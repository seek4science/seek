class CreateCultures < ActiveRecord::Migration
  def self.up
    create_table :cultures do |t|
      t.integer :organism_id
      t.integer :study_id
      t.datetime :date_at_sampling
      t.datetime :culture_start_date
      t.integer :age_at_sampling

      t.timestamps
    end
  end

  def self.down
    drop_table :cultures
  end
end
