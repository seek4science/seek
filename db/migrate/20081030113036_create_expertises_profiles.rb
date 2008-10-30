class CreateExpertisesProfiles < ActiveRecord::Migration
  def self.up
    create_table :expertises_profiles, :id=>false do |t|
      t.integer :expertise_id
      t.integer :profile_id

      t.timestamps
    end
  end

  def self.down
    drop_table :expertises_profiles
  end
end
