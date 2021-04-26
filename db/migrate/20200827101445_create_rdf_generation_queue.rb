class CreateRdfGenerationQueue < ActiveRecord::Migration[5.2]
  def change
    create_table :rdf_generation_queues do |t|
      t.integer :item_id
      t.string :item_type
      t.timestamps
    end
  end
end
