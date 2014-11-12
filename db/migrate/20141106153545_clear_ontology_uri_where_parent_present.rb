class ClearOntologyUriWhereParentPresent < ActiveRecord::Migration
  def up
    sql = "UPDATE suggested_assay_types SET ontology_uri = NULL where parent_id IS NOT NULL"
    ActiveRecord::Base.connection.execute(sql)

    sql = "UPDATE suggested_technology_types SET ontology_uri = NULL where parent_id IS NOT NULL"
    ActiveRecord::Base.connection.execute(sql)
  end

  def down
  end
end
