class LinkSuggestedTypeToParents < ActiveRecord::Migration
  def up
    update_for "assay_types"
    update_for "technology_types"
  end

  def down
  end

  private

  def update_for type
    sql = "SELECT id,parent_uri FROM suggested_#{type}"
    ActiveRecord::Base.connection.select_rows(sql).each do |record|
      parent_uri = record[1]
      unless valid_uri?(parent_uri)
        parent_id = find_parent_id(parent_uri,type)
        update_type record[0],parent_id,type
      end
    end
  end

  def update_type id,parent_id,type
    sql = "UPDATE suggested_#{type} SET parent_id=#{parent_id} WHERE id=#{id}"
    ActiveRecord::Base.connection.execute(sql)
  end

  def valid_uri? uri
    RDF::URI.new(uri).valid?
  end

  def find_parent_id uri,type
    sql = "SELECT id FROM suggested_#{type} WHERE uri='#{uri}'"
    ActiveRecord::Base.connection.select_one(sql)["id"]
  end
end
