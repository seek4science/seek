class AddRefreshDependentsToRdfGenerationQueue < ActiveRecord::Migration[5.2]
  def change
    add_column :rdf_generation_queues, :refresh_dependents, :boolean
  end
end
