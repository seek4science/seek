class CreateRecommendedModelEnvironments < ActiveRecord::Migration
  def self.up
    create_table :recommended_model_environments do |t|
      t.string :title

      t.timestamps
    end
    
  end

  def self.down
    drop_table :recommended_model_environments
  end
end
