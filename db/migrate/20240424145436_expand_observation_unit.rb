class ExpandObservationUnit < ActiveRecord::Migration[6.1]
  def change
    add_column :observation_units, :contributor_id, :bigint
    add_column :observation_units, :uuid, :string
    add_column :observation_units, :deleted_contributor, :string
    add_column :observation_units, :other_creators, :text
  end
end
